using ServerStatistics.Models;

namespace ServerStatistics.Data
{
    public interface IRepository
    {
        List<Statistics> GetStatistics();
        void Update(Statistics statistics);
    }
}