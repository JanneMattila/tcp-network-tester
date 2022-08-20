# Notes

This kind of testing is always tricky. Here are some
numbers with *very* **very** limited testing.
Your mileage *will* vary.

## Scenario

1. You have service that exposes TCP endpoint: `tcp-server`

```csharp
// Tiny C# example for illustration purposes
var tcpListener = TcpListener.Create(port);
tcpListener.Start();

// ...
var client = await tcpListener.AcceptTcpClientAsync();
// ...
```

2. Multiple simultaneously connected clients: `tcp-client`

```csharp
// Tiny C# example for illustration purposes
var client = new TcpClient(server, port);
// ...
```

3. All the clients maintain the connection
4. You host your `tcp-server` in AKS

Here is simplified scenario architecture:

![Simplified scenario architecture](https://user-images.githubusercontent.com/2357647/185667212-66cf749d-11ed-441f-823a-dce08dea5c3d.png)

## Testing

Additional component `tcp-server-stats` is helper for providing user interface
listing all `tcp-server`s and how many clients they have connected:

![Testing setup](https://user-images.githubusercontent.com/2357647/185661381-b767942b-5013-4b9c-a805-8378edff0d6d.png)

Single instance of `tcp-client` is configured to maintain `10'000` connections.

Example deployment of server contains these:
- `tcp-server-stats` 1 replica
- `tcp-server` 1 replica
  - `tcp-server-stats` address is provided as parameter for reporting purposes

### Connection via internal Pod IP

`tcp-client` has been configured with `tcp-server` address 
`10.2.0.38` which is Pod IP directly from VNet

Above whould give following result:

![1 client replicate with 10k connections](https://user-images.githubusercontent.com/2357647/185671104-39f4a179-51c0-4df7-925e-74c171132c25.png)

If you now scale `tcp-client` to 10 replicas:

![10 client replicate with total 100k connections](https://user-images.githubusercontent.com/2357647/185671375-4498a7b6-dc9a-4593-952a-a53886da999a.png)

Above means that `tcp-server` can maintain `100'000` connections.

### Connection via internal Load Balancer

`tcp-server` is exposed via Kubernetes Service using following configuration:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: tcp-server-internal-svc
  namespace: demos
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  ports:
    - port: 10000
  selector:
    app: tcp-server
```

```bash
$ kubectl get service -n demos
NAME                      TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)           AGE
tcp-server-internal-svc   LoadBalancer   10.0.100.45   10.2.0.55       10000:32264/TCP   53s
tcp-server-stats-svc      LoadBalancer   10.0.175.14   51.12.157.192   80:30643/TCP      16m
```

Above yaml configuration creates internal Load Balancer for `tcp-server`.
If you now run `tcp-client` with internal Load Balancer address 
`10.2.0.55`, you'll get similar results for 1 replica = 10k connections:

![1 client replicate with 10k connections](https://user-images.githubusercontent.com/2357647/185672150-bc615aee-d094-420c-906b-a7f4b809fa61.png)

However, if you scale above 6 instances you'll see that number of connections are gapped to 60k.

Here are more information about [Troubleshooting SNAT](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard#troubleshooting-snat)
and [Configure the allocated outbound ports](https://docs.microsoft.com/en-us/azure/aks/load-balancer-standard#configure-the-allocated-outbound-ports)

See also collection of [links](./README.md#links).

### Connection via external Load Balancer

`tcp-server` is exposed via Kubernetes Service using following configuration:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: tcp-server-svc
  namespace: demos
spec:
  type: LoadBalancer
  ports:
    - port: 10000
  selector:
    app: tcp-server
```

![Connection via external Load Balancer architecture](https://user-images.githubusercontent.com/2357647/185611178-66b6792c-242a-47e1-8cc4-874e5ea0e8f3.png)

Above configuration exposes `tcp-server` to the internet.
If you now run `tcp-client` using the external address 
`52.138.196.60`, you might notice that 1 replica still gives you
10k connections and that your connections are gapped to 60k. 
