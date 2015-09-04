var currentView = 'startView';
var serverListVisible = false;

function connectServer () {

    var serverFrame = document.getElementById('serverFrame');
    var serverAddressBox = document.getElementById('serverAddress');

    serverAddress = serverAddressBox.value;

    if (serverAddress.length < 1) {
        serverAddress = 'https://demo.rocket.chat';
    }

    serverFrame.src = serverAddress;

    changeView('server');
}

document.getElementById("serverAddressButton").addEventListener("click", connectServer);

function changeView (view) {
    var curr = document.getElementById(currentView);
    var next = document.getElementById(view + 'View');

    curr.style.display = 'none';
    next.style.display = 'block';
}

function toggleServerList () {
    if (serverListVisible) {
        serverListVisible = false;

        document.querySelector("#serverList").style.left = '-64px';
    } else {
        serverListVisible = true;

        document.querySelector("#serverList").style.left = '0px';
    }
}

document.querySelector("#serverList .toggle").addEventListener("click", toggleServerList);
