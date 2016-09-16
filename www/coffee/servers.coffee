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


	getServer: (url) ->
		return servers[url]


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
				message: cordovai18n("The_address_provided_must_be_a_string")
				url: url

		url = url.trim()
		url - url.replace /\/$/, ''

		if _.isEmpty(url)
			console.error 'url (', url, ') can\'t be empty'
			return {} =
				isValid: false
				message: cordovai18n("The_address_provided_can_not_be_empty")
				url: url

		if not /^https?:\/\/.+/.test(url)
			console.error 'url (', url, ') must start with http:// or https://'
			return {} =
				isValid: false
				message: cordovai18n("The_address_must_start_with_http_or_https")
				url: url

		atIndex = url.indexOf '@'
		auth = null
		if atIndex != -1
			auth = url.split('@')[0].split(':')[2]
		return {} =
			isValid: true
			message: cordovai18n("The_address_provided_is_valid")
			url: url
			auth: auth


	validateName: (name) ->
		if not _.isString(name)
			console.error 'name (', name, ') must be string'
			return {} =
				isValid: false
				message: cordovai18n("The_name_provided_must_be_a_string")
				name: name

		name = name.trim()

		if _.isEmpty(name)
			console.error 'name (', name, ') can\'t be empty'
			return {} =
				isValid: false
				message: cordovai18n("The_name_provided_can_not_be_empty")
				name: name

		return {} =
			isValid: true
			message: cordovai18n("The_name_provided_is_valid")
			name: name


	validateServer: (url, auth, cb) ->
		headers = {}
		if auth
			headers.Authorization = "Bearer " + auth
		request = $.ajax
			dataType: "json"
			url: "#{url}/api/info"
			headers: headers

		timeout = setTimeout ->
			request.abort()
		, 5000

		request.done (data, textStatus, jqxhr) ->
			if not data?.version?
				return cb cordovai18n("The_address_provided_is_not_a_RocketChat_server")

			versions = data.version.split('.').reverse()
			versionNum = 0
			versionMul = 1
			for version in versions
				versionNum += version * versionMul
				versionMul = versionMul * 1000

			if versionNum < 7000
				return cb cordovai18n("The_server_s_is_running_an_out_of_date_version_or_doesnt_support_mobile_applications_Please_ask_your_server_admin_to_update_to_a_new_version_of_RocketChat", url)

			clearTimeout timeout
			cb null, data

		request.fail (jqxhr, textStatus, error) ->
			if error?.name is "SyntaxError"
				return cb cordovai18n("The_server_s_is_running_an_out_of_date_version_Please_ask_your_server_admin_to_update_to_a_new_version_of_RocketChat", url)
			console.log "req failed: #{textStatus}, #{error}, #{request.status}"
			cb cordovai18n("Failed_to_connect_to_server_s_s", textStatus, error)


	getManifest: (url, cb) ->
		urlObj = @validateUrl url

		if not _.isFunction cb
			console.error 'callback is required'
			return false

		if urlObj.isValid is false
			return cb urlObj.message

		@validateServer urlObj.url, urlObj.auth, (err, data) =>
			if err?
				return cb err

			headers = {}
			if urlObj.auth
				headers.Authorization = "Bearer " + urlObj.auth
			request = $.ajax
				dataType: "json"
				url: "#{urlObj.url}/__cordova/manifest.json"
				headers: headers

			timeout = setTimeout ->
				request.abort()
			, 5000

			request.done (data, textStatus, jqxhr) ->
				if data?.manifest?.length > 0
					data.manifest.unshift
						url: '/index.html?' + Math.round(Math.random()*10000000)
						path: 'index.html'
						hash: Math.round(Math.random()*10000000)

					clearTimeout timeout
					cb null, data
				else
					cb cordovai18n("The_server_s_is_not_enable_or_mobile_apps", urlObj.url)

			request.fail (jqxhr, textStatus, error) ->
				if textStatus is 'parsererror'
					cb cordovai18n("The_server_s_is_not_enable_or_mobile_apps", urlObj.url)
				else
					cb cordovai18n("Failed_to_connect_to_server_s_s", textStatus, error)


	registerServer: (name, url, cb) ->
		nameObj = @validateName name
		urlObj = @validateUrl url

		if urlObj.isValid is false
			return cb urlObj.message

		if nameObj.isValid is false
			return cb nameObj.message

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
				oldInfo = servers[url].oldInfo
				servers[url].oldInfo = servers[url].info
				servers[url].info = info

				@downloadServer url, (status) ->
					if status?.err?
						servers[url].info = servers[url].oldInfo
						servers[url].oldInfo = oldInfo
					cb(status)


	getFileTransfer: ->
		@fileTransfer ?= new FileTransfer()
		return @fileTransfer


	uriToPath: (uri) ->
		return decodeURI(uri).replace(/^file:\/\//g, '')


	baseUrlToDir: (baseUrl) ->
		return encodeURIComponent baseUrl.toLowerCase().replace(/[\s\.\\\/:@\-]/g, '')


	downloadServer: (url, downloadServerCb) ->
		copyDownloadedFiles = (copyDownloadedFilesCb) =>
			items = servers[url].info.manifest.filter (item) ->
				return item.copied is false

			copy = (item, cb) =>
				copyFile 'file://'+item.copyFrom, item.copyTo, cb

			async.each items, copy, (err) ->
				copyDownloadedFilesCb()

		initDownloadServer = =>
			i = 0
			items = servers[url].info.manifest.filter (item) ->
				return item?.url? and item.downloaded isnt true

			download = (item, cb) =>
				if not item?.url?
					return cb()

				if item.downloaded is true
					return cb()

				@downloadFile url, item.url.replace(/\?.+$/, ''), (err, data) ->
					item.downloaded = err is undefined
					if data?
						item.copied = false
						item.copyFrom = data.from
						item.copyTo = data.to

					downloadServerCb?({done: false, count: ++i, total: items.length})
					cb(err, data)

			async.eachLimit items, 5, download, (err) ->
				if err?
					downloadServerCb?({err: err})
				else
					copyDownloadedFiles =>
						downloadServerCb?({done: true, count: items.length, total: items.length})


		filesToCopy = 0
		copiedFiles = 0

		if servers[url].oldInfo?
			for item in servers[url].info.manifest
				if item.path.indexOf('packages/rocketchat_livechat/') > -1
					item.downloaded = true
					continue

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
				if item.path.indexOf('packages/rocketchat_livechat/') > -1
					item.downloaded = true
					continue

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


	fixIndexFile: (indexDir, baseUrl, cb) ->
		urlObj = @validateUrl baseUrl
		readFile indexDir, "index.html", (err, file) =>
			if err?
				Bugsnag.notify "readIndexFileError", "Error fixing index file, index file read error",
					err: err
				return cb err

			if not file?
				Bugsnag.notify "readIndexFileNotFound", "Error fixing index file, index file not found"
				cb 'index.html not found'

			file = file.replace(/<script text="text\/javascript" src="\/shared\/.+\n/gm, '')
			file = file.replace(/<link rel="stylesheet" href="\/shared\/.+\n/gm, '')

			if urlObj.auth
				schemalessUrl = baseUrl.replace('http://', '').replace('https://', '')
				file = file.replace(/(^\s*__meteor_runtime_config__ = JSON.+$)/gm, """
					/* sandstorm workaround */ $1
				__meteor_runtime_config__.ROOT_URL = '#{baseUrl}';
				__meteor_runtime_config__.DDP_DEFAULT_CONNECTION_URL = '#{baseUrl}';
				__meteor_runtime_config__.SANDSTORM_API_TOKEN = '#{urlObj.auth}';
				__meteor_runtime_config__.SANDSTORM_API_HOST = '#{baseUrl}';

				window._OriginalWebSocket = window._OriginalWebSocket || window.WebSocket;
				window.WebSocket = function SandstormWebSocket (url, protocols) {
					url = url.replace('#{schemalessUrl}',
					"#{schemalessUrl}/.sandstorm-token/#{urlObj.auth}");
					if (protocols) {
						return new _OriginalWebSocket(url, protocols);
					} else {
						return new _OriginalWebSocket(url);
					}
				};

				XMLHttpRequest._originalOpen = XMLHttpRequest._originalOpen || XMLHttpRequest.prototype.open;
				XMLHttpRequest.prototype.open = function () {
				  var res = XMLHttpRequest._originalOpen.apply(this, arguments);
					if (arguments[1].indexOf("#{baseUrl}") === 0 && arguments[1].indexOf("#{baseUrl}/.sandstorm-login") !== 0) {
						// Only send sandstorm auth for urls in the base url.
						// Confusingly, /.sandstorm-login already sets the auth header, so skip that route.
						this.setRequestHeader("Authorization", "Bearer #{urlObj.auth}");
					}
					return res;
				}
				""")
			file = file.replace /(<\/head>)/gm, """
				<link rel="stylesheet" href="/shared/css/servers-list.css"/>
				<script text="text/javascript" src="/shared/js/android_sender_id.js"></script>
				<script text="text/javascript" src="/shared/js/share.js"></script>
				<script text="text/javascript" src="/shared/js_compiled/i18n.js"></script>
				<script text="text/javascript" src="/shared/js_compiled/utils.js"></script>
				<script text="text/javascript" src="/shared/js_compiled/servers.js"></script>
				<script text="text/javascript" src="/shared/js_compiled/servers-list.js"></script>
				$1
			"""
			writeFile indexDir, "index.html", file, =>
				cb null, file


	downloadFile: (baseUrl, path, cb) ->
		ft = @getFileTransfer()
		attempts = 0

		urlObj = @validateUrl baseUrl
		strippedUrl = baseUrl
		# urls with http basic auth seem to cause problems with cordova's download file
		if urlObj.auth
			if baseUrl
				strippedUrl = baseUrl.replace("sandstorm:#{urlObj.auth}@".toLowerCase(), '')
			if path
				path = path.replace("sandstorm:#{urlObj.auth}@".toLowerCase(), '')

		tryDownload = =>
			attempts++

			url = encodeURI "#{strippedUrl}/__cordova#{path}?#{@random()}"
			pathToSave = @uriToPath(cordova.file.dataDirectory) + @baseUrlToDir(baseUrl) + '_temp' + encodeURI(path)
			pathToSaveFinal = @uriToPath(cordova.file.dataDirectory) + @baseUrlToDir(baseUrl) + encodeURI(path)

			# console.log "start downloading", url, ', saving at', pathToSave

			downloadSuccess = (entry) =>
				if entry?
					console.log("done downloading " + path)
					cb null, {
						from: pathToSave
						to: @baseUrlToDir(baseUrl) + encodeURI(path)
					}

			downloadError = (err) =>
				if attempts < 5
					console.log "Trying (#{attempts}) #{url}"
					return tryDownload()

				console.log('downloadFile err', err)
				cb err, null

			headers = {}
			if urlObj.auth
				headers.Authorization = "Bearer " + urlObj.auth
			ft.download url, pathToSave, downloadSuccess, downloadError, true, {
	        headers: headers
		    }

		tryDownload()


	save: (cb) ->
		writeFile cordova.file.dataDirectory, 'servers.json', JSON.stringify(servers), (err, data) ->
			if err?
				console.log 'Error saving servers file', err

			cb?()


	load: ->
		timer = setTimeout @load.bind(@), 2000

		readFile cordova.file.dataDirectory, 'servers.json', (err, savedServers) =>
			clearTimeout timer
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


	startLocalServer: (path, cb) ->
		if not cb? and typeof path is 'function'
			cb = path
			path = ''

		if not httpd?
			return console.error 'CorHttpd plugin not available/ready.'

		options =
			'www_root': @uriToPath(cordova.file.applicationDirectory+'www/')
			'cordovajs_root': @uriToPath(cordova.file.applicationDirectory+'www/')
			'host': 'localhost.local'

		success = (url) =>
			console.log "server is started:", options.host
			cb? null, options.host
			location.href = "http://#{options.host}/#{path}"

		failure = (error) ->
			cb? error
			console.log 'failed to start server:', error

		httpd.startServer options, success, failure


	startServer: (baseUrl, path, cb) ->
		if not cb? and typeof path is 'function'
			cb = path
			path = ''

		if not httpd?
			return console.error 'CorHttpd plugin not available/ready.'

		if not servers[baseUrl]?
			return console.error 'Invalid baseUrl'

		options =
			'www_root': @uriToPath(cordova.file.dataDirectory) + @baseUrlToDir(baseUrl)
			'cordovajs_root': @uriToPath(cordova.file.applicationDirectory+'www/')
			'host': @baseUrlToDir(baseUrl) + '.meteor.local'

		success = (url) =>
			console.log "server is started:", url
			servers.active = baseUrl
			@save ->
				cb? null, baseUrl
				location.href = "http://#{options.host}/#{path}"

		failure = (error) ->
			cb? error
			console.log 'failed to start server:', error

		@fixIndexFile cordova.file.dataDirectory + @baseUrlToDir(baseUrl), baseUrl, (error) ->
			if error?
				cb? error
			httpd.startServer options, success, failure


	deleteServer: (url, cb) ->
		if not servers[url]?
			return

		delete servers[url]
		if servers.active is url
			delete servers.active

		removeDir(cordova.file.dataDirectory + @baseUrlToDir(url))

		@save cb
