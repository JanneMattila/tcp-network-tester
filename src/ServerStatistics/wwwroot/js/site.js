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

const addTableRow = (table, data) => {
    let row = table.insertRow(1);

    let machineNameCell = row.insertCell(0);
    machineNameCell.appendChild(document.createTextNode(data.machineName));

    let clientsCell = row.insertCell(1);
    clientsCell.appendChild(document.createTextNode(data.clients));

    let lastUpdatedCell = row.insertCell(2);
    lastUpdatedCell.appendChild(document.createTextNode(data.lastUpdated));
}

connection.on("UpdateStats", stats => {
    console.log("Statistics:");
    console.log(stats);

    const statsElement = document.getElementById("stats");
    const statsTableElement = document.getElementById("statsTable");

    while (statsTableElement.rows.length > 1) {
        statsTableElement.deleteRow(-1);
    }

    for (let i = 0; i < stats.length; i++) {
        addTableRow(statsTableElement, stats[i]);
    }

    let totalClients = 0;
    for (let i = 0; i < stats.length; i++) {
        totalClients += stats[i].clients;
    }

    statsElement.innerHTML = `${totalClients} total connected clients`;
});
