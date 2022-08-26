vm_name="vm"
vm_username="azureuser"
vm_password=$(openssl rand -base64 32)

lb_name="lb-vm"
lb_frontend_name="frontend"
lb_backend_name="backend"
lb_health_probe_name="health"
lb_rule_name="rule1"

nsg_name="nsg-vm"
nsg_rule_name="tcprule"

vm_nic_names=(vm-nic1 vm-nic2)

az network lb create \
  --resource-group $resource_group_name \
  --name $lb_name \
  --sku Standard \
  --subnet $subnet_vm_id \
  --frontend-ip-name $lb_frontend_name \
  --backend-pool-name $lb_backend_name

az network lb probe create \
  --resource-group $resource_group_name \
  --name $lb_name \
  --name $lb_health_probe_name \
  --protocol tcp \
  --port 10000

az network lb rule create \
  --resource-group $resource_group_name \
  --name $lb_name \
  --name $lb_rule_name \
  --protocol tcp \
  --frontend-port 10000 \
  --backend-port 10000 \
  --frontend-ip-name $lb_frontend_name \
  --backend-pool-name $lb_backend_name \
  --probe-name $lb_health_probe_name \
  --idle-timeout 15 \
  --enable-tcp-reset true

az network nsg create \
  --resource-group $resource_group_name \
  --name $nsg_name

az network nsg rule create \
  --resource-group $resource_group_name \
  --nsg-name $nsg_name \
  --name $nsg_rule_name \
  --protocol '*' \
  --direction inbound \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range 10000 \
  --access allow \
  --priority 100

vm_nic_names_list=$(IFS=, ; echo "${vm_nic_names[*]}")
echo $vm_nic_names_list

for vm_nic_name in "${vm_nic_names[@]}"
do
  az network nic create \
    --resource-group $resource_group_name \
    --name $vm_nic \
    --subnet $subnet_vm_id
done

vm_json=$(az vm create \
  --resource-group $resource_group_name  \
  --name $vm_name \
  --image UbuntuLTS \
  --size Standard_DS3_v2 \
  --public-ip-address "$vm_name-pip" \
  --public-ip-sku Standard \
  --nics $vm_nic_names_list \
  --nsg-rule SSH \
  --subnet $subnet_vm_id \
  --admin-username $vm_username \
  --admin-password $vm_password \
  -o json)

for vm_nic_name in "${vm_nic_names[@]}"
do
  az network nic ip-config address-pool add \
    --resource-group $resource_group_name \
    --name $lb_name \
    --address-pool $lb_backend_name \
    --ip-config-name ipconfig1 \
    --nic-name $vm_nic_name \
done
