using System.Net.Sockets;

var cancellationToken = new CancellationTokenSource();

Console.CancelKeyPress += (sender, e) =>
{
    cancellationToken.Cancel();
};

try
{
    var client = new TcpClient("localhost", 10_000);
    while (client.Connected && !cancellationToken.IsCancellationRequested)
    {
        Console.Write(".");
        await Task.Delay(1_000);
    }

    client.Close();
}
catch (ArgumentNullException e)
{
    Console.WriteLine("ArgumentNullException: {0}", e);
}
catch (SocketException e)
{
    Console.WriteLine("SocketException: {0}", e);
}
