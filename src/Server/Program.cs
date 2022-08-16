using Server;
using System.Net.Sockets;

var cancellationToken = new CancellationTokenSource();
var delay = 0;
var lastReportedCount = -1;
var buffer = new byte[1024];

Console.CancelKeyPress += (sender, e) =>
{
    cancellationToken.Cancel();
};

Console.WriteLine("Starting server");
var tcpListener = TcpListener.Create(10_000);
tcpListener.Start();

var connections = new List<ServerConnection>();

while (!cancellationToken.IsCancellationRequested)
{
    if (tcpListener.Pending())
    {
        var client = await tcpListener.AcceptTcpClientAsync(cancellationToken.Token);
        if (client != null)
        {
            client.NoDelay = true;
            connections.Add(new ServerConnection()
            {
                Client = client,
                Stream = client.GetStream(),
                LastUpdated = DateTime.Now
            });
            delay = 0;
        }
    }
    else
    {
        delay = Math.Min(delay + 10, 1000);
        await Task.Delay(delay);

        var currentCount = connections.Count;
        if (currentCount != lastReportedCount)
        {
            lastReportedCount = currentCount;
            Console.WriteLine($"{currentCount} connected");
        }
        else
        {
            var lastUpdated = DateTime.Now.Add(TimeSpan.FromSeconds(-30));
            var disconnectedClients = new List<ServerConnection>();
            foreach (var connection in connections)
            {
                if (connection.Client.Available > 0)
                {
                    await connection.Stream.ReadAsync(buffer, 0, buffer.Length);
                    connection.LastUpdated = DateTime.Now;
                }
                else if (!connection.Client.Connected ||
                    (connection.Client.Available == 0 && connection.LastUpdated < lastUpdated))
                {
                    disconnectedClients.Add(connection);
                }
            }

            if (disconnectedClients.Any())
            {
                foreach (var disconnectedClient in disconnectedClients)
                {
                    connections.Remove(disconnectedClient);
                }
            }
        }
    }
}
