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


# onIframeLoad = ->
# 	$(document.body).removeClass 'loading'
# 	iframeDocument = $($('iframe').contents()[0])
# 	iframe = $('iframe')[0]

# 	iframe.contentWindow.facebookConnectPlugin = facebookConnectPlugin
# 	iframe.contentWindow.PushNotification = PushNotification
# 	iframe.contentWindow.device = device
# 	iframe.contentWindow.open = window.open

# 	$(iframeDocument).on 'click', 'a[href^="http"]', (e) ->
# 		url = $(this).attr('href')
# 		window.open(url, '_system')
# 		e.preventDefault()

# 	iframe.contentWindow.addEventListener 'onNewVersion', (e) ->
# 		if Servers.getActiveServer().info.version is e.detail
# 			return

# 		if not confirm('There is a new version available, do you want to update now?')
# 			return

# 		$(document.body).addClass 'loading'
# 		$('.loading-text').text 'Updating files...'
# 		serverAddress = Servers.getActiveServer().url
# 		name = Servers.getActiveServer().name
# 		Servers.updateServer serverAddress, (status) ->
# 			if status.done is true
# 				$('.loading-text').text "Loading #{name}..."
# 				Servers.save()
# 				Servers.startServer serverAddress, ->
# 					showView 'server'
# 			else
# 				$('.loading-text').html "Updating files...<br/>( #{status.count} / #{status.total} )"

# 	started = undefined

# 	addSwipeEventToOpenServerList iframeDocument

# 	url = Servers.getActiveServer().url

# 	# Save all localStorage records from inframe in the main
# 	# localStorage as an objetc of key:value under the key (url)
# 	iframe.contentWindow.localStorage.setItem = (key, value) ->
# 		data = JSON.parse localStorage.getItem(url) or '{}'
# 		data[key] = value
# 		localStorage.setItem url, JSON.stringify(data)

# 		if key is 'android_senderID' and value?
# 			localStorage.setItem key, value
# 			configurePush()

# 	# Respond inframe localStorage from the main localStorage
# 	# getting from the server object
# 	iframe.contentWindow.localStorage.getItem = (key) ->
# 		data = JSON.parse localStorage.getItem(url) or '{}'
# 		return data[key]


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
		if not query.addServer?
			setTimeout ->
				loadLastActiveServer() if AUTOLOAD is true
			, 200
		navigator.splashscreen.hide()

