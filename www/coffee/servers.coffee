httpd = undefined

document.addEventListener "deviceready", ->
	httpd = cordova?.plugins?.CordovaUpdate


window.Servers = new class
	servers = {}


	constructor: ->
		@load()


	random: ->
		return Math.round(Math.random()*10000000)


	getServers: ->
		items = ({name: value.name, url: key} for key, value of servers when key isnt 'active')
		return _.sortBy items, 'name'


	getActiveServer: ->
		if servers.active? and servers[servers.active]?
			return servers.active


	validateUrl: (url) ->
		if not _.isString(url)
			console.error 'url (', url, ') must be string'
			return false

		url = url.trim().toLowerCase()
		url - url.replace /\/$/, ''

		if _.isEmpty(url)
			console.error 'url (', url, ') can\'t be empty'
			return false

		if not /^https?:\/\/.+/.test(url)
			console.error 'url (', url, ') must start with http:// or https://'
			return false

		return url


	validateName: (name) ->
		if not _.isString(name)
			console.error 'name (', name, ') must be string'
			return false

		name = name.trim()

		if _.isEmpty(name)
			console.error 'name (', name, ') can\'t be empty'
			return false

		return name


	getManifest: (url, cb) ->
		url = @validateUrl url

		if not _.isFunction cb
			console.error 'callback is required'
			return false

		if url is false
			return cb 'No address provided.'

		request = $.getJSON "#{url}/__cordova/manifest.json"
		request.done (data, textStatus, jqxhr) ->
			if not jqxhr.getResponseHeader('x-rocket-chat-version')
				cb 'The address provided is not a Rocket.Chat server.'
			else if data?.manifest?.length > 0
				data.manifest.unshift
					url: '/index.html?' + Math.round(Math.random()*10000000)

				cb null, data
			else
				cb "The version the server, #{url}, is running is out of date and doesn't support mobile applications. Please have your server admin update to a new version of Rocket.Chat."

		request.fail (jqxhr, textStatus, error) ->
			console.log 'getManifest request failed arguments:', arguments
			if not jqxhr.getResponseHeader('x-rocket-chat-version')
				cb 'The address provided is not a Rocket.Chat server.'
			else if textStatus is 'parsererror'
				cb "The version the server, #{url}, is running is out of date and doesn't support mobile applications. Please have your server admin update to a new version of Rocket.Chat."
			else
				cb "Request failed: #{textStatus}. #{error}"


	registerServer: (name, url, cb) ->
		name = @validateName name
		url = @validateUrl url

		if url is false or name is false
			return cb 'The address provided is not a valid url.'

		if servers[url]?
			console.error 'url (', url, ') already exists'
			return cb()

		@getManifest url, (err, info) =>
			if err
				return cb err

			servers[url] =
				name: name
				info: info

			@save()

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
		download = (item, cb) =>
			if not item?.url?
				return cb()

			if servers[url].oldInfo?
				found = servers[url].oldInfo.manifest.find (oldItem) ->
					return oldItem.path is item.path and oldItem.hash is item.hash

				if found?
					return cb()

			@downloadFile url, item.url.replace(/\?.+$/, ''), cb

		console.log servers[url]
		async.eachLimit servers[url].info.manifest, 5, download, ->
			downloadServerCb?()


	downloadFile: (baseUrl, path, cb) ->
		ft = @getFileTransfer()

		url = encodeURI "#{baseUrl}/__cordova#{path}?#{@random()}"
		pathToSave = @uriToPath(cordova.file.dataDirectory) + @baseUrlToDir(baseUrl) + '/' + encodeURI(path)

		# console.log "start downloading", url, ', saving at', pathToSave

		ft.download url, pathToSave, (entry) ->
			if entry?
				# console.log("done downloading " + url)
				cb null, entry
		, (err) ->
			console.log('downloadFile err', err)
			cb null, err


	save: ->
		localStorage.setItem 'servers', JSON.stringify servers


	load: ->
		savedServers = localStorage.getItem 'servers'
		if savedServers?.length > 2
			servers = JSON.parse savedServers


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
