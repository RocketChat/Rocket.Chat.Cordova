#!/usr/bin/env node

var execSync = require('child_process').execSync;
var fs = require('fs');
var request = require('request');
var Download = require('download');

execSync("rm -rf cache/*")

var server = 'https://demo.rocket.chat';


request(server+'/__cordova/manifest.json', function (error, response, body) {
	if (error || response.statusCode !== 200) {
		console.log(error);
		return;
	}

	manifest = JSON.parse(body);

	if (!Array.isArray(manifest.manifest)) {
		console.log('Invalid manifest');
	}

	manifest.manifest.forEach(function(item) {
		if (!item.url) {
			return
		}

		url = server + item.url;
		path = item.url.replace(/\?.+$/, '').split('/')
		path.pop();
		path = path.join('/');
		dest = 'cache' + path;
		new Download({mode: '755'}).get(url).dest(dest).run();
	});
});


// new Download({mode: '755'})
//     .get(server+'__cordova/manifest.json')
//     .dest('dest/cordova/teste/manifest.json')
//     .run();
