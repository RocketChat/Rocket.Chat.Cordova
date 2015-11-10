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

	# httpd.getCordovajsRoot (cordovajsRoot) ->
	# 	console.log('cordovajsRoot', cordovajsRoot)
	# 	# startServer(cordovajsRoot)
	# , (err) ->
	# 	console.log('cordovajsRoot fail', err)

window.downloadFile = (url) ->
	ft = new FileTransfer()

	console.log "start downloading " + url

	urlPrefix = 'http://localhost:3000/' + '__cordova';
	versionPrefix = uriToPath cordova.file.dataDirectory

	uri = encodeURI(urlPrefix + url + '?' + Math.round(Math.random()*10000000))

	console.log "uri", uri
	console.log "versionPrefix + encodeURI(url)", versionPrefix + encodeURI(url)

	ft.download uri, versionPrefix + encodeURI(url), (entry) ->
		if entry
			console.log("done downloading " + url)
			# if queue.length
			# 	downloadUrl queue.shift()
			# afterAllFilesDownloaded();
	, (err) ->
		console.log('downloadFile err', err)

window.startDownload = ->
	$.getJSON 'http://localhost:3000/__cordova/manifest.json', (data) ->
		if data?.manifest?.length > 0
			data.manifest.push({ url: '/index.html?' + Math.round(Math.random()*10000000) })

			for item in data.manifest when item?.url?
				window.downloadFile item.url.replace(/\?.+$/, '')


window.listDirectory = (url, options, cb) ->
	if typeof options is 'function'
		cb = options
		options = {}

	fail = (err) ->
		cb(err)

	resolveSuccess = (entry) ->
		readEntriesSuccess = (entries) ->
			window.entries = entries
			names = []
			names.push entry.name for entry in entries
			cb null, names

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
