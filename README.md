# Rocket.Chat.Cordova
Rocket.Chat Cross-Platform Mobile Application via Cordova

# !!!Attention!!!
This application only connects in servers that was compiled with mobile platforms enabled

# How to run
#### Requirements
 * npm
 * nodejs 0.12

#### Install dependencies
```shell
sudo npm install cordova coffee-script -g
```

#### Prepare - Install plataforms and plugins
```shell
cordova prepare
```

#### Run on emulator
```shell
cordova emulate ios
```
or
```shell
cordova emulate android
```

#### Run on device
```shell
cordova run ios --device
```
or
```shell
cordova run android --device
```
