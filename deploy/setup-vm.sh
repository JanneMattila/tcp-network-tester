vm_name="vm"
vm_username="azureuser"
vm_password=$(openssl rand -base64 32)

lb_name="lb-vm"
lb_frontend_name="frontend"
lb_backend_name="backend"
lb_health_probe_name="health"
lb_rule_tcp_name="tcp-rule"
lb_rule_ssh_name="ssh-rule"

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
  --port 22

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
  --disable-outbound-snat true \
  --enable-tcp-reset true

az network lb rule create \
  --resource-group $resource_group_name \
  --lb-name $lb_name \
  --name $lb_rule_ssh_name \
  --protocol tcp \
  --frontend-port 22 \
  --backend-port 22 \
  --frontend-ip-name $lb_frontend_name \
  --backend-pool-name $lb_backend_name \
  --probe-name $lb_health_probe_name \
  --idle-timeout 15 \
  --disable-outbound-snat true \
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

az network vnet subnet update \
  --resource-group $resource_group_name \
  --vnet-name $vnet_name \
  --name $subnet_vm_name \
  --network-security-group $nsg_name

vm_nic_names_list=$(IFS=, ; echo "${vm_nic_names[*]}")
echo $vm_nic_names_list
vm_nic_ids=()

for vm_nic_name in "${vm_nic_names[@]}"
do
  echo $vm_nic_name
  az network public-ip create \
    --resource-group $resource_group_name  \
    --sku Standard \
    --allocation-method Static \
    --name "pip-$vm_nic_name"

  vm_nic_id=$(az network nic create \
    --resource-group $resource_group_name \
    --name $vm_nic_name \
    --public-ip-address "pip-$vm_nic_name" \
    --vnet-name $vnet_name \
    --subnet $subnet_vm_name \
    --accelerated-networking true \
    --lb-name $lb_name \
    --lb-address-pools $lb_backend_name \
    --query NewNIC.id -o tsv)
  echo $vm_nic_id
  vm_nic_ids+=($vm_nic_id)
done

vm_nic_ids_list=$(IFS=, ; echo "${vm_nic_ids[*]}" | tr "," " ")
echo $vm_nic_ids_list

vm_json=$(az vm create \
  --resource-group $resource_group_name  \
  --name $vm_name \
  --image UbuntuLTS \
  --nics $vm_nic_ids_list \
  --size Standard_DS3_v2 \
  --admin-username $vm_username \
  --admin-password $vm_password)

vm_public_ip_addresses=$(echo $vm_json | jq -r .publicIpAddress)
vm_private_ip_addresses=$(echo $vm_json | jq -r .privateIpAddress)
echo $vm_public_ip_addresses
echo $vm_private_ip_addresses

vm_public_ip_address=$(echo $vm_public_ip_addresses | cut -d "," -f 1)
vm_private_ip_address=$(echo $vm_private_ip_addresses | cut -d "," -f 1)
echo $vm_public_ip_address
echo $vm_private_ip_address

# Display variables
# Remember to enable auto export
set -a
echo vm_username=$vm_username
echo vm_password=$vm_password
echo stats_server_address=$stats_server_address
echo vm_public_ip_address=$vm_public_ip_address
echo vm_private_ip_address=$vm_private_ip_address
echo lb_public_ip_address=$lb_public_ip_address

ssh $vm_username@$vm_public_ip_address
ssh $vm_username@$lb_public_ip_address

# Or using sshpass
sshpass -p $vm_password ssh $vm_username@$vm_public_ip_address
sshpass -p $vm_password ssh $vm_username@$lb_public_ip_address

# Setup VM
sudo apt update
sudo apt install docker.io -y

# Update your public stats server address
stats_server_address=11.22.33.44

sudo docker run --rm -p "10000:10000" \
  -e PORT=10000 \
  -e INTERVAL=1000 \
  -e REPORTURI=http://$stats_server_address/api/ServerStatistics \
  -e REPORTINTERVAL=10 \
  jannemattila/tcp-network-tester-server:1.0.2

# Exit VM
exit
