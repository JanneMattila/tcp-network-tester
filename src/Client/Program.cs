using Client;
using Microsoft.Extensions.Configuration;
using System.Net.Sockets;

var builder = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
#if DEBUG
    .AddUserSecrets<Program>()
#endif
    .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
    .AddEnvironmentVariables();

var configuration = builder.Build();

var server = configuration.GetValue<string>("server");
var port = configuration.GetValue<int>("port");
var clientCount = configuration.GetValue<int>("clientCount");
var interval = configuration.GetValue<int>("interval");

var cancellationToken = new CancellationTokenSource();
var connections = new List<ClientConnection>();
var buffer = new byte[1];

Console.CancelKeyPress += (sender, e) =>
{
    cancellationToken.Cancel();
};

try
{
    Console.WriteLine($"{DateTime.Now} Creating {clientCount} client connections");

    for (int i = 0; i < clientCount; i++)
    {
        var client = new TcpClient(server, port)
        {
            NoDelay = true
        };

        connections.Add(new ClientConnection(client, client.GetStream()));
    }

    Console.WriteLine($"{DateTime.Now} Created {clientCount} client connections");
    while (!cancellationToken.IsCancellationRequested)
    {
        var start = DateTime.Now;
        foreach (var connection in connections)
        {
            await connection.Stream.WriteAsync(buffer, 0, buffer.Length, cancellationToken.Token);
        }

        var end = DateTime.Now;
        var update = (int)(end - start).TotalSeconds;
        Console.WriteLine($"{DateTime.Now} Updated {connections.Count} connections to server. It took {update} seconds. Continue after {interval} seconds.");

        if (update < interval)
        {
            await Task.Delay(TimeSpan.FromSeconds(interval - update), cancellationToken.Token);
        }
    }

    foreach (var connection in connections)
    {
        connection.Stream.Close();
        connection.Client.Close();
        connection.Client.Dispose();
    }
}
catch (ArgumentNullException e)
{
    Console.WriteLine("ArgumentNullException: {0}", e);
}
catch (SocketException e)
{
    Console.WriteLine("SocketException: {0}", e);
}
