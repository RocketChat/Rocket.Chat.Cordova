httpd = undefined

document.addEventListener "deviceready", ->
	httpd = cordova?.plugins?.CordovaUpdate
	window.startServer()

window.log = console.log.bind(console)

uriToPath = (uri) ->
	return decodeURI(uri).replace(/^file:\/\//g, '')

window.startServer = (wwwroot) ->
	if not httpd?
		return console.log 'CorHttpd plugin not available/ready.'

	cordovaRoot = uriToPath(window.location.href).replace(/\/index.html$/, '/');
	console.log 'cordovaRoot', cordovaRoot
	console.log 'uriToPath cordova.file.dataDirectory', uriToPath cordova.file.dataDirectory
	options =
		'www_root': uriToPath cordova.file.dataDirectory
		'cordovajs_root': cordovaRoot
		# 'port': 8080

	success = (url) ->
		console.log "server is started:", url
		# updateStatus()

	failure = (error) ->
		# document.getElementById('url').innerHTML = 'failed to start server: ' + error
		console.log 'failed to start server:', error

	httpd.startServer options, success, failure

	# Generate a index.html file to prevent application crash
	# writeFile(cordova.file.dataDirectory, 'index.html', 'index.html', log)


window.listDirectory = (url, options, cb) ->
	if typeof options is 'function'
		cb = options
		options = {}

	fail = (err) ->
		# cb(err)

	resolveSuccess = (entry) ->
		readEntriesSuccess = (entries) ->
			window.entries = entries
			names = []
			for entry in entries
				names.push entry.name
				console.log entry.name
			# cb null, names

		reader = entry.createReader()
		reader.readEntries readEntriesSuccess, fail

	window.resolveLocalFileSystemURL url, resolveSuccess, fail


window.writeFile = (directoryPath, fileName, content, cb) ->
	fail = (err) ->
		cb err, null

	resolveSuccess = (dirEntry) ->
		getFileSuccess = (fileEntry) ->
			createWriterSuccess = (writer) ->
				writer.onwrite = (evt, a) ->
					cb null, evt.target.result

				writer.onerror = fail
				writer.write content

			fileEntry.createWriter createWriterSuccess, fail

		getFileOptions =
			create: true
			exclusive: false

		dirEntry.getFile fileName, getFileOptions, getFileSuccess, fail

	window.resolveLocalFileSystemURL directoryPath, resolveSuccess, fail


window.writeDir = (directoryPath, dirName, cb) ->
	fail = (err) ->
		cb err, null

	resolveSuccess = (dirEntry) ->
		getDirectorySuccess = (fileEntry) ->
			console.log('created')

		dirEntry.getDirectory dirName, {create: true}, getDirectorySuccess, fail

	window.resolveLocalFileSystemURL directoryPath, resolveSuccess, fail
