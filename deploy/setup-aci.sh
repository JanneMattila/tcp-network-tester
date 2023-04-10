servers_resource_group="rg-aci-servers"
clients_resource_group="rg-aci-clients"
location="northeurope"

az group create --name $servers_resource_group --location $location
az group create --name $clients_resource_group --location $location

statistics_server_json=$(az container create \
  --name "aci-server-stats" \
  --image "jannemattila/tcp-network-tester-server-stats" \
  --ports 80 \
  --cpu 1 \
  --memory 1 \
  --resource-group $servers_resource_group \
  --restart-policy Always \
  --ip-address public -o json)
statistics_server=$(echo $statistics_server_json | jq -r .ipAddress.ip)

server_json=$(az container create \
  --name "aci-server" \
  --image "jannemattila/tcp-network-tester-server" \
  --ports 80 10000 \
  --cpu 2 \
  --memory 4 \
  --resource-group $servers_resource_group \
  --environment-variables "port=10000" "interval=60" "reportUri=http://$statistics_server/api/ServerStatistics" "reportInterval=60" \
  --restart-policy Always \
  --ip-address public -o json)
server=$(echo $server_json | jq -r .ipAddress.ip)

az container create \
  --name $(date +%s) \
  --image "jannemattila/tcp-network-tester-client" \
  --cpu 1 \
  --memory 1 \
  --resource-group $clients_resource_group \
  --environment-variables "port=10000" "interval=60" "server=$server" "clientCount=30000" \
  --restart-policy Always

az group delete --name $servers_resource_group -y
az group delete --name $clients_resource_group -y
