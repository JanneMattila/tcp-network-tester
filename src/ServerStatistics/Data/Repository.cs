using ServerStatistics.Models;
using System.Collections.Concurrent;

namespace ServerStatistics.Data;

public class Repository : IRepository
{
    private readonly ConcurrentDictionary<string, Statistics> _stats = new();

    public void Update(Statistics statistics)
    {
        _stats.Remove(statistics.MachineName, out _);
        _stats[statistics.MachineName] = statistics;
    }

    public List<Statistics> GetStatistics()
    {
        return _stats.Values.ToList();
    }
}
