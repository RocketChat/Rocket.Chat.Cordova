#!/usr/bin/env node

var execSync = require('child_process').execSync;
var fs = require('fs');
var request = require('request');

execSync("rm -rf www/cache/*");

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

	fs.writeFileSync('www/js/cache_manifest.js', 'window.cacheManifest = '+JSON.stringify(manifest), 'utf8');

	manifest.manifest.forEach(function(item) {
		if (!item.url) {
			return;
		}

		var url = server + '/__cordova' + item.url;
		var path = item.url.replace(/\?.+$/, '').split('/');
		var name = path.pop();
		path = path.join('/');
		var dest = 'www/cache' + path;

		request({url: url, encoding: null}, function (error, response, body) {
			if (error) {
				return console.log(url, error);
			}
			if (response.statusCode !== 200) {
				return console.log(url, response.statusCode);
			}

			execSync("mkdir -p "+dest);
			fs.writeFileSync(dest+'/'+name, body);
		});
	});
});
