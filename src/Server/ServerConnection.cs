using System.Net.Sockets;

namespace Server;

public class ServerConnection
{
    public TcpClient Client { get; private set; }
    public NetworkStream Stream { get; private set; }
    public DateTime LastUpdated { get; set; }

    public ServerConnection(TcpClient client, NetworkStream stream)
    {
        Client = client;
        Stream = stream;
        LastUpdated = DateTime.Now;
    }
}
