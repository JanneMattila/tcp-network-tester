using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using ServerStatistics.Data;
using ServerStatistics.Hubs;
using ServerStatistics.Models;

namespace ServerStatistics.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ServerStatisticsController : ControllerBase
{
    private readonly IHubContext<ServerStatisticsHub> _hub;
    private readonly IRepository _repository;

    public ServerStatisticsController(IHubContext<ServerStatisticsHub> hub, IRepository repository)
    {
        _hub = hub;
        _repository = repository;
    }

    [HttpPost]
    public async Task Post([FromBody] Statistics statistics)
    {
        _repository.Update(statistics);
        var stats = _repository.GetStatistics();
        await _hub.Clients.All.SendAsync("UpdateStats", stats);
    }
}
