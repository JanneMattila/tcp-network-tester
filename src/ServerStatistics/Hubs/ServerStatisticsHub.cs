using Microsoft.AspNetCore.SignalR;
using ServerStatistics.Data;

namespace ServerStatistics.Hubs;

public class ServerStatisticsHub : Hub
{
    protected readonly ILogger _log;
    private readonly IRepository _repository;

    public ServerStatisticsHub(ILogger<ServerStatisticsHub> log, IRepository repository)
    {
        _log = log;
        _repository = repository;
    }

    public override async Task OnConnectedAsync()
    {
        await base.OnConnectedAsync();

        var stats = _repository.GetStatistics();
        await Clients.Caller.SendAsync("UpdateStats", stats);
    }
}
