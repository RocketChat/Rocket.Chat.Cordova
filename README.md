# Rocket.Chat.Cordova
Rocket.Chat Cross-Platform Mobile Application via Cordova

# DEPRECATED
As of March (3/18) this application has been deprecated and is no longer maintained. 

Please see our native mobile apps:
- iOS - [here](https://github.com/RocketChat/Rocket.Chat.iOS)
- Android - [here](https://github.com/RocketChat/Rocket.Chat.Android)

Both apps can be found in their respective app stores by searching for: `Rocket.Chat`

Cordova app will not be able to connect to Rocket.Chat server 0.72.0 and higher as support has been removed.



### Development

#### Requirements
 * npm
 * nodejs 0.12
 * ImageMagick (with support for legacy utilities)

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


## Assets
- `1024 x 1024` **icon-android.png** (can use transparent background)
- `1024 x 1024` **icon-ios.png**
- `2208 x 2208` **splash-android.png**
- `2208 x 2208` **splash-ipad.png**
- `2208 x 2208` **splash-iphone.png**

Examples https://github.com/RocketChat/Rocket.Chat.Cordova/tree/develop/assets
