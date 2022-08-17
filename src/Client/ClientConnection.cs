using System.Net.Sockets;

namespace Client;

public class ClientConnection
{
    public TcpClient Client { get; private set; }
    public NetworkStream Stream { get; private set; }

    public ClientConnection(TcpClient client, NetworkStream stream)
    {
        Client = client;
        Stream = stream;
    }
}
