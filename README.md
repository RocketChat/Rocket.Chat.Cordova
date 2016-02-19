# Rocket.Chat.Cordova
Rocket.Chat Cross-Platform Mobile Application via Cordova

# !!!Attention!!!
This application only connects with servers that were compiled with mobile platforms enabled

# How to run
#### Requirements
 * npm
 * nodejs 0.12

#### Install dependencies
```shell
sudo npm install cordova coffee-script -g
npm install
```

### Create Conf files
```
echo 'Bugsnag.apiKey = "YOUR-API-KEY-HERE";' > www/js/bugsnag_apikey.js
echo 'window.ANDROID_SENDER_ID = "YOUR-ANDROID-ID-HERE";' > www/shared/js/android_sender_id.js
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

#### Troubleshooting

Some have had issues with a couple of dependencies not being installed by npm.
Running: `npm install ticons underscore` may be necessary.
