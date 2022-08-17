# Enable auto export
set -a

# All the variables for the deployment
subscription_name="AzureDev"
azuread_admin_group_contains="janne''s"

aks_name="myakstcp"
acr_name="cmyakstcp000000010"
workspace_name="log-myakstcpworkspace"
vnet_name="vnet-myakstcp"
subnet_aks_name="snet-aks"
cluster_identity_name="id-myakstcp-cluster"
kubelet_identity_name="id-myakstcp-kubelet"
resource_group_name="rg-myakstcp"
location="swedencentral"

# Login and set correct context
az login -o table
az account set --subscription $subscription_name -o table

# Prepare extensions and providers
az extension add --upgrade --yes --name aks-preview

# Enable feature
az feature register --namespace "Microsoft.ContainerService" --name "PodSubnetPreview"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/PodSubnetPreview')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService

# Remove extension in case conflicting previews
# az extension remove --name aks-preview

az group create -l $location -n $resource_group_name -o table

azuread_admin_group_id=$(az ad group list --display-name $azuread_admin_group_contains --query [].id -o tsv)
echo $azuread_admin_group_id

acr_json=$(az acr create -l $location -g $resource_group_name -n $acr_name --sku Basic -o json)
echo $acr_json
acr_loginServer=$(echo $acr_json | jq -r .loginServer)
acr_id=$(echo $acr_json | jq -r .id)
echo $acr_loginServer
echo $acr_id

workspace_id=$(az monitor log-analytics workspace create -g $resource_group_name -n $workspace_name --query id -o tsv)
echo $workspace_id

vnet_id=$(az network vnet create -g $resource_group_name --name $vnet_name \
  --address-prefix 10.0.0.0/8 \
  --query newVNet.id -o tsv)
echo $vnet_id

subnet_aks_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_name \
  --name $subnet_aks_name --address-prefixes 10.2.0.0/24 \
  --query id -o tsv)
echo $subnet_aks_id

subnet_storage_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_name \
  --name $subnet_storage_name --address-prefixes 10.3.0.0/24 \
  --query id -o tsv)
echo $subnet_storage_id

# Delegate a subnet to Azure NetApp Files
# https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-delegate-subnet
subnet_netapp_id=$(az network vnet subnet create -g $resource_group_name --vnet-name $vnet_name \
  --name $subnet_netapp_name --address-prefixes 10.4.0.0/28 \
  --delegations "Microsoft.NetApp/volumes" \
  --query id -o tsv)
echo $subnet_netapp_id

cluster_identity_json=$(az identity create --name $cluster_identity_name --resource-group $resource_group_name -o json)
kubelet_identity_json=$(az identity create --name $kubelet_identity_name --resource-group $resource_group_name -o json)
cluster_identity_id=$(echo $cluster_identity_json | jq -r .id)
kubelet_identity_id=$(echo $kubelet_identity_json | jq -r .id)
kubelet_identity_object_id=$(echo $kubelet_identity_json | jq -r .principalId)
echo $cluster_identity_id
echo $kubelet_identity_id
echo $kubelet_identity_object_id

az aks get-versions -l $location -o table

# Note: for public cluster you need to authorize your ip to use api
my_ip=$(curl --no-progress-meter https://api.ipify.org)
echo $my_ip

# Enable Ultra Disk:
# --enable-ultra-ssd

aks_json=$(az aks create -g $resource_group_name -n $aks_name \
 --max-pods 50 --network-plugin azure \
 --node-count 1 --enable-cluster-autoscaler --min-count 1 --max-count 4 \
 --node-osdisk-type Ephemeral \
 --node-vm-size Standard_D8ds_v4 \
 --kubernetes-version 1.23.8 \
 --enable-addons monitoring \
 --enable-aad \
 --enable-azure-rbac \
 --disable-local-accounts \
 --aad-admin-group-object-ids $azuread_admin_group_id \
 --workspace-resource-id $workspace_id \
 --attach-acr $acr_id \
 --load-balancer-sku standard \
 --vnet-subnet-id $subnet_aks_id \
 --assign-identity $cluster_identity_id \
 --assign-kubelet-identity $kubelet_identity_id \
 --api-server-authorized-ip-ranges $my_ip \
 -o json)

aks_node_resource_group_name=$(echo $aks_json | jq -r .nodeResourceGroup)
aks_node_resource_group_id=$(az group show --name $aks_node_resource_group_name --query id -o tsv)
echo $aks_node_resource_group_id

###################################################################
# Enable current ip
az aks update -g $resource_group_name -n $aks_name --api-server-authorized-ip-ranges $my_ip

# Clear all authorized ip ranges
az aks update -g $resource_group_name -n $aks_name --api-server-authorized-ip-ranges ""
###################################################################

sudo az aks install-cli
az aks get-credentials -n $aks_name -g $resource_group_name --overwrite-existing
kubelogin convert-kubeconfig -l azurecli

kubectl get nodes

kubectl apply -f deploy/00_namespace.yaml
kubectl apply -f deploy/01_service.yaml

# Build images to ACR
docker tag tcp-network-tester-server:latest "$acr_loginServer/tcp-network-tester-server:latest"
docker push "$acr_loginServer/tcp-network-tester-server:latest"

# Set deployment variables
registry_name=$acr_loginServer
image_name=tcp-network-tester-server
image_tag=latest

kubectl apply -f deploy/02_deployment.yaml
cat deploy/deployment.yaml | envsubst | kubectl apply -f -

kubectl get deployment -n demos
kubectl describe deployment -n demos

kubectl get pod -n demos -o wide
kubectl describe pod -n demos

kubectl get pod -n demos
pod1=$(kubectl get pod -n demos -o name | head -n 1)
echo $pod1

kubectl describe $pod1 -n demos

kubectl get service -n demos

ingress_ip=$(kubectl get service -n demos -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
echo $ingress_ip

curl $ingress_ip
# -> OK!

# Wipe out the resources
az group delete --name $resource_group_name -y
