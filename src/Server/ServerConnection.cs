using System.Net.Sockets;

namespace Server;

public class ServerConnection
{
    public TcpClient Client { get; set; }
    public NetworkStream Stream { get; set; }
    public DateTime LastUpdated { get; set; }
}
