# TCP Network tester

Helper application for testing TCP related setups such as Load Balancers

## Development

### Server Statistics

```bash
# Build container image
docker build -t tcp-network-tester-server-stats:latest -f .\src\ServerStatistics\Dockerfile .

# Run container using command
docker run --rm -p "2001:80" -p "2002:443" tcp-network-tester-server-stats:latest:latest
``` 