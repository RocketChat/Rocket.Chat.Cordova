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


#### Prepare - Install platforms and plugins
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

## I can't connect to my server instance
If you are running your server using the command `meteor` you should define the URL where the mobile application will try to connect `meteor --mobile-server http://192.168.1.10:3000`, replace **http://192.168.1.10:3000** by your IP or domain.

This is necessary because the mobile application download all files to run locally and then start the connection with your server, as you are running as develop mode this is necessary.
