using Client;
using Microsoft.Extensions.Configuration;
using System.Diagnostics;
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
    Console.WriteLine($"{DateTime.Now} Closing application");

    cancellationToken.Cancel();
};

try
{
    Console.WriteLine($"{DateTime.Now} Creating {clientCount} client connections");

    var timer = Stopwatch.StartNew();
    var previous = 0;
    for (int i = 0; i < clientCount; i++)
    {
        try
        {
            var client = new TcpClient(server, port)
            {
                NoDelay = true
            };

            connections.Add(new ClientConnection(client, client.GetStream()));
            if (timer.ElapsedMilliseconds > 1_000)
            {
                Console.WriteLine($"{DateTime.Now} Creating client connections: {i + 1} of {clientCount} ({i - previous + 1} created in last second)");
                timer.Restart();
                previous = i;
            }
        }
        catch (SocketException socketEx)
        {
            Console.WriteLine($"{DateTime.Now} Exception while creating TcpClients: {socketEx}");
            break;
        }
    }

    if (!connections.Any())
    {
        Console.WriteLine($"{DateTime.Now} Couldn't create a single client. Exiting!");
        return;
    }

    Console.WriteLine($"{DateTime.Now} Created {clientCount} client connections");
    while (!cancellationToken.IsCancellationRequested)
    {
        foreach (var connection in connections)
        {
            await connection.Stream.WriteAsync(buffer, 0, buffer.Length, cancellationToken.Token);
        }

        Console.WriteLine($"{DateTime.Now} Updated {connections.Count} connections to server. Continue after {interval} seconds.");
        await Task.Delay(TimeSpan.FromSeconds(interval), cancellationToken.Token);
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
