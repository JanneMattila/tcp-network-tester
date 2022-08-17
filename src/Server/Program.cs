using Microsoft.Extensions.Configuration;
using Server;
using System.Net.Http.Json;
using System.Net.Sockets;

var builder = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
#if DEBUG
    .AddUserSecrets<Program>()
#endif
    .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
    .AddEnvironmentVariables();

var configuration = builder.Build();

var port = configuration.GetValue<int>("port");
var interval = configuration.GetValue<int>("interval");

var reportUri = configuration.GetValue<string>("reportUri");
var reportInterval = configuration.GetValue<int>("reportInterval");

var cancellationToken = new CancellationTokenSource();
var delay = 0;
var lastReportedCount = -1;
var buffer = new byte[1024];
var connections = new List<ServerConnection>();
var httpClient = new HttpClient();
var lastReported = DateTime.Now;

Console.CancelKeyPress += (sender, e) =>
{
    cancellationToken.Cancel();
};

Console.WriteLine("Starting server");
var tcpListener = TcpListener.Create(port);
tcpListener.Start();

while (!cancellationToken.IsCancellationRequested)
{
    if (!string.IsNullOrEmpty(reportUri) &&
        lastReported < DateTime.Now.AddSeconds(-reportInterval))
    {
        try
        {
            await httpClient.PostAsJsonAsync(reportUri, new ServerStatistics()
            {
                MachineName = Environment.MachineName,
                Clients = connections.Count
            });
            lastReported = DateTime.Now;
        }
        catch (Exception ex)
        {
            Console.WriteLine(ex.ToString());
        }
    }

    if (tcpListener.Pending())
    {
        var client = await tcpListener.AcceptTcpClientAsync(cancellationToken.Token);
        if (client != null)
        {
            client.NoDelay = true;
            connections.Add(new ServerConnection(client, client.GetStream()));
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
            Console.WriteLine($"{DateTime.Now} {currentCount} connected");
        }
        else
        {
            var lastUpdated = DateTime.Now.Add(TimeSpan.FromSeconds(-interval));
            var disconnectedClients = new List<ServerConnection>();

            var start = DateTime.Now;
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

            var end = DateTime.Now;
            var update = (int)(end - start).TotalSeconds;
            Console.WriteLine($"{DateTime.Now} Validated {connections.Count} client connections. It took {update} seconds. Disconnecting {disconnectedClients.Count} client connections.");

            if (disconnectedClients.Any())
            {
                foreach (var disconnectedClient in disconnectedClients)
                {
                    try
                    {
                        disconnectedClient.Stream.Close();
                        disconnectedClient.Client.Close();
                        disconnectedClient.Client.Dispose();
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"{DateTime.Now} Exception while disconnecting client: {ex}");
                    }
                    connections.Remove(disconnectedClient);
                }
            }
        }
    }
}
