# This Dockerfile contains Build and Release steps:
# 1. Build image(https://hub.docker.com/_/microsoft-dotnet-core-sdk/)
FROM mcr.microsoft.com/dotnet/sdk:6.0.400-1-alpine3.16-amd64 AS build
WORKDIR /source

# Cache nuget restore
COPY "src/ServerStatistics/ServerStatistics.csproj" .
RUN dotnet restore "ServerStatistics.csproj"

# Copy sources and compile
COPY "src/ServerStatistics" .
RUN dotnet publish "ServerStatistics.csproj" --output /app/ --configuration Release

# 2. Release image
FROM mcr.microsoft.com/dotnet/aspnet:6.0.8-alpine3.16-amd64
WORKDIR /app

EXPOSE 80
EXPOSE 443

# Copy content from Build image
COPY --from=build /app .

ENTRYPOINT ["dotnet", "ServerStatistics.dll"]
