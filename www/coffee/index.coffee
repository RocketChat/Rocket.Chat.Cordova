ANDROID_SENDER_ID = undefined
AUTOLOAD = true

registerServer = ->
	serverAddress = $('#serverAddress').val().trim().toLowerCase()

	if serverAddress.length is 0
		serverAddress = 'https://demo.rocket.chat'

	if not /^https?:\/\/.+/.test serverAddress
		serverAddress = 'http://' + serverAddress

	name = serverAddress.replace(/https?:\/\//, '').replace(/^www\./, '')

	$(document.body).addClass 'loading'
	$('.loading-text').text 'Validating server...'

	setTimeout ->
		Servers.registerServer name, serverAddress, (err) ->
			if err?
				console.error "Failed to register the server #{serverAddress}: #{err}"

				return setTimeout ->
					# do this a few milliseconds later so the screen doesn't appear
					# to flash when they're on a fast connection
					$('#serverAddress').addClass 'error'
					# $('#serverAddressButton').prop 'disabled', true
					addAlert { type: 'danger', message: err }
					$(document.body).removeClass 'loading'
				, 1500

			refreshServerList()

			$('.loading-text').text 'Downloading files...'
			Servers.downloadServer serverAddress, (status) ->
				if status.done is true
					$('.loading-text').text "Loading #{name}..."
					Servers.save()
					Servers.startServer serverAddress, ->
						#
				else
					$('.loading-text').html "Downloading files...<br/>( #{status.count} / #{status.total} )"
	, 250


updateServer = (url, version) ->
	server = Servers.getServer url

	if not server?
		return

	if server.info.version is version
		return

	$(document.body).addClass 'loading'
	$('.loading-text').text 'Updating files...'

	name = server.name
	Servers.updateServer url, (status) ->
		if status.done is true
			$('.loading-text').text "Loading #{server.name}..."
			Servers.save()
			Servers.startServer url, ->
				#
		else
			$('.loading-text').html "Updating files...<br/>( #{status.count} / #{status.total} )"


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


# window.addEventListener 'native.keyboardshow', (e) ->
# 	if device?.platform.toLowerCase() isnt 'android'
# 		$('.keyboard').css 'bottom', e.keyboardHeight


# window.addEventListener 'native.keyboardhide', ->
# 	if device?.platform.toLowerCase() isnt 'android'
# 		$('.keyboard').css 'bottom', 0


# document.addEventListener 'pause', (e) ->
# 	$('iframe')[0].contentDocument.dispatchEvent(e)


# document.addEventListener 'resume', (e) ->
# 	$('iframe')[0].contentDocument.dispatchEvent(e)


window.loadLastActiveServer = ->
	activeServer = Servers.getActiveServer()
	if activeServer?
		$(document.body).addClass 'loading'
		$('.loading-text').text "Loading #{activeServer.name}..."
		Servers.startServer activeServer.url, (err, url) ->
			if err?
				# TODO err
				return console.log err


document.addEventListener "deviceready", ->
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
		cordova.plugins.Keyboard.close()
		setTimeout ->
			registerServer()
		, 100

	# $('iframe').on 'load', onIframeLoad
	$('#serverAddress').on 'input', serverAddressInput

	Servers.onLoad ->
		configurePush()
		refreshServerList()
		navigator.splashscreen.hide()
		if query.updateServer?
			return updateServer(decodeURIComponent(query.updateServer), decodeURIComponent(query.version))

		if not query.addServer?
			setTimeout ->
				loadLastActiveServer() if AUTOLOAD is true
			, 200
