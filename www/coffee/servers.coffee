httpd = undefined

document.addEventListener "deviceready", ->
	httpd = cordova?.plugins?.CordovaUpdate


window.Servers = new class
	servers = {}


	constructor: ->
		@loadCallbacks = []
		document.addEventListener "deviceready", =>
			@load()


	random: ->
		return Math.round(Math.random()*10000000)


	serverExists: (url) ->
		return servers[url]?


	getServers: ->
		items = ({name: value.name, url: key} for key, value of servers when key isnt 'active')
		return _.sortBy items, 'name'


	getActiveServer: ->
		if servers.active? and servers[servers.active]?
			return {
				url: servers.active
				name: servers[servers.active].name
				info: servers[servers.active].info
			}


	setActiveServer: (url) ->
		if servers[url]?
			servers.active = url
			return @save()


	validateUrl: (url) ->
		if not _.isString(url)
			console.error 'url (', url, ') must be string'
			return {} =
				isValid: false
				message: 'The address provided must be a string.'
				url: url

		url = url.trim().toLowerCase()
		url - url.replace /\/$/, ''

		if _.isEmpty(url)
			console.error 'url (', url, ') can\'t be empty'
			return {} =
				isValid: false
				message: 'The address provided can not be empty.'
				url: url

		if not /^https?:\/\/.+/.test(url)
			console.error 'url (', url, ') must start with http:// or https://'
			return {} =
				isValid: false
				message: 'The address must start with http:// or https://'
				url: url

		return {} =
			isValid: true
			message: 'The address provided is valid.'
			url: url


	validateName: (name) ->
		if not _.isString(name)
			console.error 'name (', name, ') must be string'
			return {} =
				isValid: false
				message: 'The name provided must be a string.'
				name: name

		name = name.trim()

		if _.isEmpty(name)
			console.error 'name (', name, ') can\'t be empty'
			return {} =
				isValid: false
				message: 'The name provided can not be empty.'
				name: name

		return {} =
			isValid: true
			message: 'The name provided is valid.'
			name: name


	getManifest: (url, cb) ->
		urlObj = @validateUrl url

		if not _.isFunction cb
			console.error 'callback is required'
			return false

		if urlObj.isValid is false
			return cb urlObj.message

		request = $.getJSON "#{urlObj.url}/__cordova/manifest.json"

		timeout = setTimeout ->
			request.abort()
		, 5000

		request.done (data, textStatus, jqxhr) ->
			if not jqxhr.getResponseHeader('x-rocket-chat-version')
				cb 'The address provided is not a Rocket.Chat server.'
			else if data?.manifest?.length > 0
				data.manifest.unshift
					url: '/index.html?' + Math.round(Math.random()*10000000)

				clearTimeout timeout
				cb null, data
			else
				cb "The server #{urlObj.url} is running an out of date version or doesn't support mobile applications. Please ask your server admin to update to a new version of Rocket.Chat."

		request.fail (jqxhr, textStatus, error) ->
			console.log 'getManifest request failed arguments:', arguments
			if not jqxhr.getResponseHeader('x-rocket-chat-version')
				cb 'The address provided is not a Rocket.Chat server.'
			else if textStatus is 'parsererror'
				cb "The server #{urlObj.url} is running an out of date version or doesn't support mobile applications. Please ask your server admin to update to a new version of Rocket.Chat."
			else
				cb "Request failed: #{textStatus}. #{error}"


	registerServer: (name, url, cb) ->
		nameObj = @validateName name
		urlObj = @validateUrl url

		if urlObj.isValid is false
			return cb urlObj.message

		if nameObj.isValid is false
			return cb nameObj.message

		if servers[url]?
			console.error 'url (', url, ') already exists'
			return cb()

		@getManifest url, (err, info) =>
			if err
				return cb err

			servers[url] =
				name: name
				info: info

			cb()


	updateServer: (url, cb) ->
		if not servers[url]?
			console.error 'invalid server url', url

		@getManifest url, (err, info) =>
			if err
				return cb err

			if servers[url].info.version isnt info.version
				servers[url].oldInfo = servers[url].info
				servers[url].info = info

				@downloadServer url, cb


	getFileTransfer: ->
		@fileTransfer ?= new FileTransfer()
		return @fileTransfer


	uriToPath: (uri) ->
		return decodeURI(uri).replace(/^file:\/\//g, '')


	baseUrlToDir: (baseUrl) ->
		return encodeURIComponent baseUrl.replace(/[\s\.\\\/:]/g, '')


	downloadServer: (url, downloadServerCb) ->
		initDownloadServer = =>
			i = 0
			total = servers[url].info.manifest.filter((item) -> item.downloaded isnt true).length

			download = (item, cb) =>
				if not item?.url?
					return cb()

				if item.downloaded is true
					return cb()

				@downloadFile url, item.url.replace(/\?.+$/, ''), (err, data) ->
					item.downloaded = err is undefined
					downloadServerCb?({done: false, count: i++, total: total})
					cb(err, data)

			async.eachLimit servers[url].info.manifest, 5, download, ->
				downloadServerCb?({done: true})


		filesToCopy = 0
		copiedFiles = 0

		if servers[url].oldInfo?
			for item in servers[url].info.manifest
				found = null
				servers[url].oldInfo.manifest.some (oldItem) ->
					if oldItem.path is item.path and oldItem.hash is item.hash
						found = oldItem
						return true
				if found?
					item.downloaded = true

			initDownloadServer()

		else if cacheManifest?.manifest?
			for item in servers[url].info.manifest
				found = null
				cacheManifest.manifest.some (oldItem) ->
					if oldItem.path is item.path and oldItem.hash is item.hash
						found = oldItem
						return true

				if found?.url?
					path = found.url.replace(/\?.+$/, '')
					from = cordova.file.applicationDirectory + 'www/cache' + path
					to = @baseUrlToDir(url) + path
					filesToCopy++
					item.downloaded = true
					copyFile from, to, ->
						copiedFiles++
						if filesToCopy is copiedFiles
							initDownloadServer()

		else
			initDownloadServer()


	downloadFile: (baseUrl, path, cb) ->
		ft = @getFileTransfer()
		attempts = 0

		tryDownload = =>
			attempts++

			url = encodeURI "#{baseUrl}/__cordova#{path}?#{@random()}"
			pathToSave = @uriToPath(cordova.file.dataDirectory) + @baseUrlToDir(baseUrl) + '/' + encodeURI(path)

			# console.log "start downloading", url, ', saving at', pathToSave

			downloadSuccess = (entry) =>
				if entry?
					console.log("done downloading " + path)
					if path is '/index.html'
						readFile cordova.file.dataDirectory, @baseUrlToDir(baseUrl) + '/' + encodeURI(path), (err, file) =>
							file = file.replace(/<script.*src=['"].*cordova\.js.*['"].*<\/script>/gm, '<script>window.cordova = {plugins: {CordovaUpdate: {}}, file: {}};</script>')
							writeFile cordova.file.dataDirectory, @baseUrlToDir(baseUrl) + '/' + encodeURI(path), file, =>
								cb null, entry
					else
						cb null, entry

			downloadError = (err) =>
				if attempts < 5
					console.log "Trying (#{attempts}) #{url}"
					return tryDownload()

				console.log('downloadFile err', err)
				cb null, err

			ft.download url, pathToSave, downloadSuccess, downloadError, true

		tryDownload()


	save: ->
		# localStorage.setItem 'servers', JSON.stringify servers
		writeFile cordova.file.dataDirectory, 'servers.json', JSON.stringify(servers), (err, data) ->
			if err?
				console.log 'Error saving servers file', err


	load: ->
		# savedServers = localStorage.getItem 'servers'
		readFile cordova.file.dataDirectory, 'servers.json', (err, savedServers) =>
			if savedServers?.length > 2
				servers = JSON.parse savedServers
			@loaded = true
			cb() for cb in @loadCallbacks


	onLoad: (cb) ->
		if @loaded is true
			return cb()

		@loadCallbacks.push cb


	clear: ->
		localStorage.setItem 'servers', JSON.stringify {}
		servers = {}


	startServer: (baseUrl, cb) ->
		if not httpd?
			return console.error 'CorHttpd plugin not available/ready.'

		if not servers[baseUrl]?
			return console.error 'Invalid baseUrl'

		options =
			'www_root': @uriToPath(cordova.file.dataDirectory) + @baseUrlToDir(baseUrl)
			'cordovajs_root': @uriToPath(window.location.href).replace(/\/index.html$/, '/')

		success = (url) =>
			console.log "server is started:", url
			servers.active = baseUrl
			@save()
			cb? null, baseUrl
			document.getElementById('serverFrame').src = 'http://meteor.local/'

		failure = (error) ->
			cb? error
			console.log 'failed to start server:', error

		httpd.startServer options, success, failure

		# Generate a index.html file to prevent application crash
		# writeFile(cordova.file.dataDirectory, 'index.html', 'index.html', log)


	deleteServer: (url) ->
		if not servers[url]?
			return

		delete servers[url]
		if servers.active is url
			delete servers.active

		removeDir(cordova.file.dataDirectory + @baseUrlToDir(url))

		@save()
