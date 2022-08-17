namespace ServerStatistics.Models;

public class Statistics
{
    public string MachineName { get; set; } = string.Empty;
    public int Clients { get; set; }
    public DateTime LastUpdated { get; set; }
}
