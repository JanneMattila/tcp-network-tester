using System.Net.Sockets;

var cancellationToken = new CancellationTokenSource();

Console.CancelKeyPress += (sender, e) =>
{
    cancellationToken.Cancel();
};

try
{
    using var client = new TcpClient("localhost", 10_000);
    using var stream = client.GetStream();
    while (client.Connected && !cancellationToken.IsCancellationRequested)
    {
        Console.Write(".");
        await stream.WriteAsync(new byte[1], 0, 0, cancellationToken.Token);
        await Task.Delay(15_000, cancellationToken.Token);
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
