using System.Net.Sockets;

namespace Client;

public class ClientConnection
{
    public TcpClient Client { get; set; }
    public NetworkStream Stream { get; set; }
}
