let protocol = new signalR.JsonHubProtocol();
let hubRoute = "ServerStatistics";
let connection = new signalR.HubConnectionBuilder()
    .withUrl(hubRoute)
    .withAutomaticReconnect()
    .withHubProtocol(protocol)
    .build();

connection.start()
    .then(() => {
        console.log("Connected!");
    })
    .catch((err) => {
        console.log(err);
    });

connection.on("UpdateStats", stats => {
    console.log("Statistics:");
    console.log(stats);
});
