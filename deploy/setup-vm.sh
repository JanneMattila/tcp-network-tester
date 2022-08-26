vm_name="vm"
vm_username="azureuser"
vm_password=$(openssl rand -base64 32)

lb_name="lb-vm"
lb_frontend_name="frontend"
lb_backend_name="backend"
lb_health_probe_name="health"
lb_rule_tcp_name="tcp-rule"

nsg_name="nsg-vm"
nsg_rule_tcp_name="tcp-rule"
nsg_rule_ssh_name="ssh-rule"

vm_nic_names=(vm-nic1 vm-nic2)

lb_public_ip_json=$(az network public-ip create \
  --resource-group $resource_group_name  \
  --sku Standard \
  --allocation-method Static \
  --name "pip-lb")
lb_public_ip_id=$(echo $lb_public_ip_json | jq -r .publicIp.id)
lb_public_ip_address=$(echo $lb_public_ip_json | jq -r .publicIp.ipAddress)
echo $lb_public_ip_id
echo $lb_public_ip_address

az network lb create \
  --resource-group $resource_group_name \
  --name $lb_name \
  --sku Standard \
  --public-ip-address $lb_public_ip_id \
  --frontend-ip-name $lb_frontend_name \
  --backend-pool-name $lb_backend_name

az network lb probe create \
  --resource-group $resource_group_name \
  --lb-name $lb_name \
  --name $lb_health_probe_name \
  --protocol tcp \
  --port 10000

az network lb rule create \
  --resource-group $resource_group_name \
  --lb-name $lb_name \
  --name $lb_rule_tcp_name \
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
  --name $nsg_rule_tcp_name \
  --protocol '*' \
  --direction inbound \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range 10000 \
  --access allow \
  --priority 100

az network nsg rule create \
  --resource-group $resource_group_name \
  --nsg-name $nsg_name \
  --name $nsg_rule_ssh_name \
  --protocol '*' \
  --direction inbound \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range 22 \
  --access allow \
  --priority 200

vm_nic_names_list=$(IFS=, ; echo "${vm_nic_names[*]}")
echo $vm_nic_names_list
vm_nic_ids=()

for vm_nic_name in "${vm_nic_names[@]}"
do
  echo $vm_nic_name
  vm_nic_id=$(az network nic create \
    --resource-group $resource_group_name \
    --name $vm_nic_name \
    --subnet $subnet_vm_id \
    --accelerated-networking true \
    --query NewNIC.id -o tsv)
  echo $vm_nic_id
  vm_nic_ids+=($vm_nic_id)
done

vm_public_ip_json=$(az network public-ip create \
  --resource-group $resource_group_name  \
  --sku Standard \
  --allocation-method Static \
  --name "pip-$vm_name")
vm_public_ip_id=$(echo $vm_public_ip_json | jq -r .publicIp.id)
vm_public_ip_address=$(echo $vm_public_ip_json | jq -r .publicIp.ipAddress)
echo $vm_public_ip_id
echo $vm_public_ip_address

vm_json=$(az vm create \
  --resource-group $resource_group_name  \
  --name $vm_name \
  --image UbuntuLTS \
  --public-ip-address $vm_public_ip_id \
  --size Standard_DS3_v2 \
  --accelerated-networking true \
  --nsg $nsg_name \
  --admin-username $vm_username \
  --admin-password $vm_password)

# Need to deallocate to add NICs
az vm deallocate \
  --resource-group $resource_group_name  \
  --name $vm_name

for vm_nic_name in "${vm_nic_names[@]}"
do
  echo $vm_nic_name
  az vm nic add \
    --resource-group $resource_group_name \
    --vm-name $vm_name \
    --nics $vm_nic_name
done

for vm_nic_name in "${vm_nic_names[@]}"
do
  echo $vm_nic_name
  az network nic ip-config address-pool add \
    --resource-group $resource_group_name \
    --lb-name $lb_name \
    --address-pool $lb_backend_name \
    --ip-config-name ipconfig1 \
    --nic-name $vm_nic_name
done

az vm start \
  --resource-group $resource_group_name  \
  --name $vm_name

echo $vm_password
echo stats_server_address=$stats_server_address
echo $vm_public_ip_address
ssh $vm_username@$vm_public_ip_address

# Or using sshpass
sshpass -p $vm_password ssh $vm_username@$vm_public_ip_address

# Setup VM
sudo apt update
sudo apt install docker.io -y

# Update your public stats server address
# stats_server_address=11.22.33.44

sudo docker run --rm -p "10000:10000" \
  -e PORT=10000 \
  -e INTERVAL=1000 \
  -e REPORTURI=http://$stats_server_address/api/ServerStatistics \
  -e REPORTINTERVAL=10 \
  jannemattila/tcp-network-tester-server:latest

# Exit VM
exit
