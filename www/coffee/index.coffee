Bugsnag.metaData =
	platformId: cordova.platformId
	platformVersion: cordova.platformVersion
	deviceVersion: window.device?.version

AUTOLOAD = true

HOME_URL = 'http://gromby.com'

window.registerServer = (serverAddress) ->

	if not /^https?:\/\/.+/.test serverAddress
		serverAddress = 'http://' + serverAddress

	name = serverAddress.replace(/https?:\/\//, '').replace(/^www\./, '')

	$(document.body).addClass 'loading'
	$('.loading-text').text cordovai18n("Validating_server")

	setTimeout ->
		Servers.registerServer name, serverAddress, (err) ->
			if err?
				console.error cordovai18n("Failed_to_register_the_server_s_s", serverAddress, err)

				return setTimeout ->
					# do this a few milliseconds later so the screen doesn't appear
					# to flash when they're on a fast connection
					$('#serverAddress').addClass 'error'
					# $('#serverAddressButton').prop 'disabled', true
					addAlert { type: 'danger', message: err }
					$(document.body).removeClass 'loading'
				, 1500

			refreshServerList()

			$('.loading-text').text cordovai18n("Downloading_files")
			Servers.downloadServer serverAddress, (status) ->
				if status.done is true
					$('.loading-text').text cordovai18n("Loading_s", serverAddress)
					Servers.save ->
						Servers.startServer serverAddress, ->
							#
				else
					$('.loading-text').html cordovai18n("Downloading_files_s_s", status.count, status.total)
	, 250


updateServer = (url, version) ->
	server = Servers.getServer url

	if not server?
		return

	if server.info.version is version
		return

	$(document.body).addClass 'loading'
	$('.loading-text').text cordovai18n("Updating_files")

	name = server.name
	Servers.updateServer url, (status) ->
		if status.done is true
			$('.loading-text').text cordovai18n("Loading_s", server.name)
			Servers.save()
			Servers.startServer url, ->
				#
		else
			$('.loading-text').html cordovai18n("Updating_files_s_s", status.count, status.total)


serverAddressInput = ->
	# remove the error class when they change the input
	if $('#serverAddress').hasClass 'error'
		setTimeout ->
			$('#serverAddress').removeClass 'error'
			# $('#serverAddressButton').prop 'disabled', false
			$('#alert-messages').empty()
		, 1000


addAlert = (alertObj) ->
	if not _.isString(alertObj.type) or not _.isString(alertObj.message)
		console.warn 'The alertObj', alertObj, 'is not a valid alert object, requires both type and message properties'
		return

	$('#alert-messages').append "<div class='alert alert-#{alertObj.type}' role='alert'>#{alertObj.message}</div>"


window.configurePush = ->
	config =
		ios:
			alert: "true"
			badge: "true"
			sound: "true"
		android:
			senderID: ANDROID_SENDER_ID
			sound: true
			vibrate: true

	window.push = PushNotification.init config

	push.on 'notification', (data) ->
		if data.additionalData.foreground is true
			return

		if typeof data.additionalData.ejson is 'string'
			data.additionalData.ejson = JSON.parse data.additionalData.ejson

		host = data.additionalData.ejson.host
		if not host?
			return

		host = host.replace /\/$/, ''
		if Servers.serverExists(host) isnt true
			return

		AUTOLOAD = false

		if not data.additionalData.ejson?.rid?
			return

		path = ''

		switch data.additionalData.ejson.type
			when 'c'
				path = 'channel/' + data.additionalData.ejson.name
			when 'p'
				path = 'group/' + data.additionalData.ejson.name
			when 'd'
				path = 'direct/' + data.additionalData.ejson.sender.username

		Servers.startServer host, path, (err, url) ->
			if err?
				# TODO err
				return console.log err


	push.on 'error', (data) ->
		console.log 'err', data


window.loadLastActiveServer = ->
	activeServer = Servers.getActiveServer()
	if activeServer?
		$(document.body).addClass 'loading'
		$('.loading-text').text cordovai18n("Loading_s", activeServer.name)
		Servers.startServer activeServer.url, (err, url) ->
			if err?
				# TODO err
				return console.log err
	else
		registerServer(HOME_URL)

document.addEventListener "deviceready", ->
	navigator.appInfo.getAppInfo (appInfo) ->
		Bugsnag.appVersion = appInfo.version
		Bugsnag.metaData.version = appInfo.version
		Bugsnag.metaData.build = appInfo.build

	queryString = location.search.replace(/^\?/, '')
	query = {}
	if queryString.length > 0
		for item in queryString.split('&')
			[key, value] = item.split('=')
			query[key] = value or true

	cordova.plugins?.Keyboard?.hideKeyboardAccessoryBar? true
	cordova.plugins?.Keyboard?.disableScroll? true

	$('form').on 'submit', (e) ->
		e.preventDefault()
		e.stopPropagation()
		cordova.plugins.Keyboard.close()
		setTimeout ->
			loadLastActiveServer() if AUTOLOAD is true
		, 200

	$('.server-list-info').on 'click', (e) ->
		toggleServerList()

	# $('iframe').on 'load', onIframeLoad
	$('#serverAddress').on 'input', serverAddressInput

	Servers.onLoad ->
		configurePush()
		refreshServerList()
		navigator.splashscreen.hide()
		if query.updateServer?
			return updateServer(decodeURIComponent(query.updateServer), decodeURIComponent(query.version))

		$('.server-enter').removeClass 'hidden'
