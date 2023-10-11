# TCP Network tester

Helper application for testing TCP related setups such as Load Balancers

## Development

### Server Statistics

```bash
# Build container image
docker build -t tcp-network-tester-server-stats:latest -f .\src\ServerStatistics\Dockerfile .

# Run container using command
docker run --rm -p "2001:80" -p "2002:443" tcp-network-tester-server-stats:latest
```

### Server

```bash
# Build container image
docker build -t tcp-network-tester-server:latest -f .\src\Server\Dockerfile .

# Run container using command
docker run --rm -p "10000:10000" tcp-network-tester-server:latest
```

### Client

```bash
# Build container image
docker build -t tcp-network-tester-client:latest -f .\src\Client\Dockerfile .

# Run container using command
docker run --rm tcp-network-tester-client:latest
```

## Links

[Troubleshoot SNAT exhaustion and connection timeouts](https://docs.microsoft.com/en-us/azure/load-balancer/troubleshoot-outbound-connection)

[Use Source Network Address Translation (SNAT) for outbound connections](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections)

> Each IP address provides 64,000 ports that can be used for SNAT

[How do I check my SNAT port usage and allocation?](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-standard-diagnostics#how-do-i-check-my-snat-port-usage-and-allocation)

[What is Virtual Network NAT?](https://docs.microsoft.com/en-us/azure/virtual-network/nat-gateway/nat-overview)

[NAT Gateway performance](https://docs.microsoft.com/en-us/azure/virtual-network/nat-gateway/nat-gateway-resource#performance)

> Each NAT gateway public IP address provides 64,512 SNAT ports

> A single NAT gateway can scale up to 16 IP addresses

=> `16 IPs * 64'512 SNAT ports = 1'032'192`

[NAT Gateway limits](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits?toc=%2Fazure%2Fvirtual-network%2Ftoc.json#nat-gateway-limits)

[Dive deep into NAT gateway’s SNAT port behavior](https://azure.microsoft.com/en-us/blog/dive-deep-into-nat-gateway-s-snat-port-behavior/)

[AKS & Managed NAT Gateway](https://docs.microsoft.com/en-us/azure/aks/nat-gateway)

**Note**: If you have Public AKS and you have used `--api-server-authorized-ip-ranges $my_ip`,
then Nodes might report following failure, when you create AKS:

```bash
ERROR: (CreateVMSSAgentPoolFailed) Unable to establish connection from agents to Kubernetes API server, 
please see https://aka.ms/aks-required-ports-and-addresses for more information. Details: Code="VMExtensionProvisioningError" ...
```

You can create NAT Gateway before creating AKS and use it's Public IP Prefix range to the
`--api-server-authorized-ip-ranges` parameter.

From [https://serverfault.com/a/533612](https://serverfault.com/a/533612):

> On the TCP level the tuple (source ip, source port, destination ip, destination port)
> must be unique for each simultaneous connection. That means a single client cannot open
> more than 65535 simultaneous connections to a single server. 
> But a server can (theoretically) serve 65535 simultaneous connections per client.

From [Azure Load Balancer algorithm](https://learn.microsoft.com/en-us/azure/load-balancer/concepts):

> By default, Azure Load Balancer uses a five-tuple hash.
> The five tuple includes:
> - Source IP address
> - Source port
> - Destination IP address
> - Destination port
> - IP protocol number to map flows to available servers

Good explanation of [SNAT with App Service](https://4lowtherabbit.github.io/blogs/2019/10/SNAT/).
