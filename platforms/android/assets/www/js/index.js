var currentView = 'startView';

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
