namespace Server;

public class ServerStatistics
{
    public string MachineName { get; set; } = string.Empty;
    public int Clients { get; set; }
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
}
