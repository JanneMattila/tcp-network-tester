using ServerStatistics.Models;
using System.Collections.Concurrent;

namespace ServerStatistics.Data;

public class Repository : IRepository
{
    private readonly ConcurrentDictionary<string, Statistics> _stats = new();

    public void Update(Statistics statistics)
    {
        _stats.TryRemove(statistics.MachineName, out _);
        statistics.LastUpdated = DateTime.UtcNow;
        _stats[statistics.MachineName] = statistics;
    }

    public List<Statistics> GetStatistics()
    {
        var expired = _stats
            .Where(o => o.Value.LastUpdated < DateTime.UtcNow.AddMinutes(-1))
            .ToList();
        foreach (var item in expired)
        {
            _stats.TryRemove(item.Value.MachineName, out _);
        }

        var items = _stats.Values.ToList();
        return items;
    }
}
