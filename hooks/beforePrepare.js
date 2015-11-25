#!/usr/bin/env node

var execSync = require('child_process').execSync;
var fs = require('fs');

var coffee_path = 'www/coffee/'

if (!fs.existsSync(coffee_path)) {
    fs.mkdirSync(coffee_path)
}

execSync("rm -rf www/shared/js_compiled/*")
execSync("coffee --compile --output www/shared/js_compiled/ " + coffee_path)

if (!fs.existsSync('www/js/android_sender_id.js')) {
	throw new Error('\n#\n# The file "www/js/android_sender_id.js" does not exists!!!\n#\n# Please create the file with content:\n#\n#    window.ANDROID_SENDER_ID = "YOUR ANDROID ID"; \n#\n#');
}
