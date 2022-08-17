# This Dockerfile contains Build and Release steps:
# 1. Build image(https://hub.docker.com/_/microsoft-dotnet-core-sdk/)
FROM mcr.microsoft.com/dotnet/sdk:6.0.400-1-alpine3.16-amd64 AS build
WORKDIR /source

# Cache nuget restore
COPY "src/Server/Server.csproj" .
RUN dotnet restore "Server.csproj"

# Copy sources and compile
COPY "src/Server" .
RUN dotnet publish "Server.csproj" --output /app/ --configuration Release

# 2. Release image
FROM mcr.microsoft.com/dotnet/runtime:6.0.8-alpine3.16-amd64
WORKDIR /app
EXPOSE 10000

# Copy content from Build image
COPY --from=build /app .

ENTRYPOINT ["dotnet", "Server.dll"]
