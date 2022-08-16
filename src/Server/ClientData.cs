using System.Net.Sockets;

namespace Server;

public class ClientData
{
    public TcpClient TcpClient { get; set; }
    public DateTime LastUpdated { get; set; }
}
