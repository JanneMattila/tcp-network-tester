using Client;
using System.Net.Sockets;

var cancellationToken = new CancellationTokenSource();
var connections = new List<ClientConnection>();
var clientCount = 10_000;
var buffer = new byte[1];

Console.CancelKeyPress += (sender, e) =>
{
    cancellationToken.Cancel();
};

try
{
    for (int i = 0; i < clientCount; i++)
    {
        var client = new TcpClient("localhost", 10_000)
        {
            NoDelay = true
        };

        connections.Add(new ClientConnection()
        {
            Client = client,
            Stream = client.GetStream()
        });
    }

    while (!cancellationToken.IsCancellationRequested)
    {
        foreach (var connection in connections)
        {
            await connection.Stream.WriteAsync(buffer, 0, buffer.Length, cancellationToken.Token);
        }
        await Task.Delay(15_000, cancellationToken.Token);
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
