var currentView = 'startView';
var serverListVisible = false;

var config = {};

function verifyServer () {

    var serverFrame = document.getElementById('serverFrame');
    var serverAddressBox = document.getElementById('serverAddress');

    serverAddress = serverAddressBox.value;

    if (serverAddress.length < 1) {
        serverAddress = 'https://demo.rocket.chat';
    }

    var server = {
        name : config.servers.length+1,
        url : serverAddress
    };

    console.log(server, serverAddress);

    appendServer(server);

    connectServer(server);
}

function connectServer (server) {
    serverFrame.src = server.url;

    config.activeServer = server;
    saveConfig();

    changeView('server');
}

document.getElementById("serverAddressButton").addEventListener("click", verifyServer);

function changeView (view) {
    var curr = document.getElementById(currentView);

    nextView = view + 'View';

    var next = document.getElementById(nextView);

    curr.style.display = 'none';
    next.style.display = 'block';

    currentView = nextView;

    toggleServerList(false);
}

function toggleServerList (open) {

    if (serverListVisible || !open) {
        serverListVisible = false;

        document.querySelector("#serverList").style.left = '-64px';
    } else {
        serverListVisible = true;

        document.querySelector("#serverList").style.left = '0px';
    }
}

document.querySelector("#serverList .toggle").addEventListener("click", toggleServerList);

function loadConfig (cb) {
    if (typeof localStorage.config !== undefined) {
        try {
            config = JSON.parse(localStorage.config);
        } catch (e) {
            config = {
                servers: []
            };
        }
    }

    if (typeof (config.servers) === undefined) {
        config = {
            servers: []
        };
    }

    if (typeof(cb) !== 'undefined') {
        cb();
    }
}

function saveConfig (cb) {
    localStorage.setItem('config', JSON.stringify(config));

    if (typeof(cb) !== 'undefined') {
        cb();
    }
}

function appendServer(server) {
    var list = document.querySelector("#serverList ul");

    var lastChild = list.lastChild;

    var serv = document.createElement('LI');

    serv.dataset.name = server.name;
    serv.dataset.url = server.url;
    serv.className = 'server';

    serv.innerText = server.name;

    serv.addEventListener('click', loadServer);

    list.insertBefore(serv, lastChild);

    config.servers.push(server);

    saveConfig();
}

function loadServer (e) {
    var target = e.target;

    var data = target.dataset;

    var server = {
        name : data.name,
        url : data.url
    }

    connectServer(server);
}

function populateServerList() {
    var list = document.querySelector("#serverList ul");

    if (typeof (config.servers) !== 'undefined' && Array.isArray(config.servers)) {
        for (var i = 0;i<config.servers.length;i++) {
            var server = document.createElement('LI');

            server.dataset.name = config.servers[i].name;
            server.dataset.url = config.servers[i].url;
            server.className = 'server';

            server.innerText = config.servers[i].name;

            server.addEventListener('click', loadServer);

            list.appendChild(server);
        }
    } else {
        config.servers = [];
    }

    var serverButton = document.createElement('LI');

    serverButton.className = 'addServer';
    serverButton.innerText = '+';

    serverButton.addEventListener("click", function () {
        changeView('start');
    });

    list.appendChild(serverButton);

    if (typeof (config.activeServer) !== 'undefined') {
        console.log(typeof config.activeServer)
      connectServer(config.activeServer);
    }
}

loadConfig(populateServerList)
