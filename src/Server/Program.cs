using Server;
using System.Net.Sockets;

var cancellationToken = new CancellationTokenSource();
var delay = 0;
var lastReportedCount = -1;

Console.CancelKeyPress += (sender, e) =>
{
    cancellationToken.Cancel();
};

Console.WriteLine("Starting server");
var tcpListener = TcpListener.Create(10_000);
tcpListener.Start();

var clients = new List<ClientData>();

while (!cancellationToken.IsCancellationRequested)
{
    if (tcpListener.Pending())
    {
        var tcpClient = await tcpListener.AcceptTcpClientAsync(cancellationToken.Token);
        if (tcpClient != null)
        {
            clients.Add(new ClientData()
            {
                TcpClient = tcpClient,
                LastUpdated = DateTime.Now
            });
            delay = 0;
        }
    }
    else
    {
        delay = Math.Min(delay + 10, 1000);
        await Task.Delay(delay);

        var currentCount = clients.Count;
        if (currentCount != lastReportedCount)
        {
            lastReportedCount = currentCount;
            Console.WriteLine($"{Environment.NewLine}{currentCount} connected.");
        }
        else
        {
            var lastUpdated = DateTime.Now.Add(TimeSpan.FromSeconds(-30));
            var disconnectedClients = new List<ClientData>();
            foreach (var client in clients)
            {
                if (client.TcpClient.Available == 0 && client.LastUpdated < lastUpdated)
                {
                    disconnectedClients.Add(client);
                }
                else if (!client.TcpClient.Connected)
                {
                    disconnectedClients.Add(client);
                }
                else if (client.TcpClient.Available > 0)
                {
                    using var stream = client.TcpClient.GetStream();
                    var buffer = new byte[1024];
                    await stream.ReadAsync(buffer, 0, buffer.Length);
                    client.LastUpdated = DateTime.Now;
                }
            }

            if (disconnectedClients.Any())
            {
                foreach (var disconnectedClient in disconnectedClients)
                {
                    clients.Remove(disconnectedClient);
                }
            }
            Console.Write(".");
        }
    }
}
