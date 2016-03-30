#!/usr/bin/env node

module.exports = function(context) {
	var Q = context.requireCordovaModule('q');
	var deferral = new Q.defer();
	var execSync = require('child_process').execSync;
	var fs = require('fs');
	var ticons = require('ticons');
	var _ = require('underscore');

	var coffee_path = 'www/coffee/';

	if (!fs.existsSync(coffee_path)) {
		fs.mkdirSync(coffee_path);
	}

	execSync("rm -rf www/shared/js_compiled/*");
	execSync("coffee --compile --output www/shared/js_compiled/ " + coffee_path);

	if (!fs.existsSync('www/shared/js/android_sender_id.js')) {
		throw new Error('\n#\n# The file "www/shared/js/android_sender_id.js" does not exists!!!\n#\n# Please create the file with content:\n#\n#    window.ANDROID_SENDER_ID = "YOUR-ANDROID-ID-HERE"; \n#\n#');
	}

	if (!fs.existsSync('www/js/bugsnag_apikey.js')) {
		throw new Error('\n#\n# The file "www/js/bugsnag_apikey.js" does not exists!!!\n#\n# Please create the file with content:\n#\n#    Bugsnag.apiKey = "YOUR-API-KEY-HERE"; \n#\n#');
	}

	if (fs.existsSync('resources/icons/DefaultIcon-ios.png')) {
		var ressourceMTime = +fs.statSync('resources/icons/DefaultIcon-ios.png').mtime;
		var iconIOsMTime = +fs.statSync('assets/icon-ios.png').mtime;
		var iconAndroidMTime = +fs.statSync('assets/icon-android.png').mtime;
		var splashIPhoneMTime = +fs.statSync('assets/splash-iphone.png').mtime;
		var splashIPadMTime = +fs.statSync('assets/splash-ipad.png').mtime;
		var splashAndroidMTime = +fs.statSync('assets/splash-android.png').mtime;

		var assetMTime = Math.max(iconIOsMTime, iconAndroidMTime, splashIPhoneMTime, splashIPadMTime, splashAndroidMTime);

		if (assetMTime <= ressourceMTime) {
			return;
		}
	}

	console.log('New assets, compiling resources...');

	var assetsConfig = {
		minDpi: 160,
		maxDpi: 640,
		sdkVersion: '4.0.0',
		radius: 0,
		alloy: false,
		platforms: ['iphone', 'ios', 'ipad', 'android'],
		orientations: ['portrait', 'landscape'],
		label: false,
		crop: false,
		fix: true,
		nine: false
	};

	ticons.icons(_.extend(assetsConfig, {
		input: 'assets/icon-ios.png',
		outputDir: 'resources/icons',
		platforms: ['iphone', 'ipad']
	}), function (err, output) {
		if (err) throw err;

		console.log('GENERATED: iOS icons');

		ticons.icons(_.extend(assetsConfig, {
			input: 'assets/icon-android.png',
			outputDir: 'resources/icons',
			platforms: ['android']
		}), function (err, output) {
			if (err) throw err;

			console.log('GENERATED: Android icons');

			ticons.splashes(_.extend(assetsConfig, {
				input: 'assets/splash-iphone.png',
				outputDir: 'resources/splash',
				platforms: ['iphone', 'ipad']
			}), function (err, output) {
				if (err) throw err;

				console.log('GENERATED: iPhone splashes');

				ticons.splashes(_.extend(assetsConfig, {
					input: 'assets/splash-ipad.png',
					outputDir: 'resources/splash',
					platforms: ['iphone', 'ipad']
				}), function (err, output) {
					if (err) throw err;

					console.log('GENERATED: iPad splashes');

					ticons.splashes(_.extend(assetsConfig, {
						input: 'assets/splash-android.png',
						outputDir: 'resources/splash',
						platforms: ['android']
					}), function (err, output) {
						if (err) throw err;

						console.log('GENERATED: Android splashes');
						deferral.resolve();
					});
				});
			});
		});
	});

	return deferral.promise;
};
