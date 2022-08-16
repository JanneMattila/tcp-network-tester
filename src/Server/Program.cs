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

var clients = new List<TcpClient>();

while (!cancellationToken.IsCancellationRequested)
{
    if (tcpListener.Pending())
    {
        var client = await tcpListener.AcceptTcpClientAsync(cancellationToken.Token);
        if (client != null)
        {
            clients.Add(client);
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
            var disconnectedClients = new List<TcpClient>();
            foreach (var client in clients)
            {
                if (!client.Connected)
                {
                    disconnectedClients.Add(client);
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
