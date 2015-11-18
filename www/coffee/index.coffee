showView = (view) ->
	$('.view').addClass 'hidden'

	$('#' + view + 'View').removeClass 'hidden'


addSwipeEventToOpenServerList = ($el) ->
	started = undefined

	$el.on 'touchstart', (e) ->
		if e.originalEvent.touches.length is 2
			started =
				date: Date.now()
				pageX: e.originalEvent.touches[0].pageX
				pageY: e.originalEvent.touches[0].pageY

	$el.on 'touchmove', (e) ->
		if started?
			if Date.now() - started.date < 2000
				if Math.abs(e.originalEvent.touches[0].pageX - started.pageX) < 50
					if Math.abs(e.originalEvent.touches[0].pageY - started.pageY) > 100
						toggleServerList()
						started = undefined

	$el.on 'touchend', (e) ->
		started = undefined


window.toggleServerList = (open) ->
	if open is true
		$(document.body).addClass 'server-list-open'
	else if open is false
		$(document.body).removeClass 'server-list-open'
	else
		$(document.body).toggleClass 'server-list-open'


window.refreshServerList = ->
	ul = document.querySelector("#serverList ul")

	while ul.children[0]
		ul.children[0].remove()

	for server in Servers.getServers()
		li = """
			<li class="server">
				<div data-name="#{server.name}" data-url="#{server.url}" class="name">#{server.name}</div>
				<div data-name="#{server.name}" data-url="#{server.url}" class="delete-btn">X</div>
			</li>
		"""

		ul.appendChild $(li)[0]


	li = document.createElement('LI')

	li.className = 'addServer'
	li.innerText = '+'

	ul.appendChild li


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
						showView 'server'
				else
					$('.loading-text').html "Downloading files...<br/>( #{status.count} / #{status.total} )"
	, 250


onIframeLoad = ->
	$(document.body).removeClass 'loading'
	iframeDocument = $($('iframe').contents()[0])
	iframe = $('iframe')[0]

	iframe.contentWindow.facebookConnectPlugin = facebookConnectPlugin
	iframe.contentWindow.PushNotification = PushNotification
	iframe.contentWindow.device = device
	iframe.contentWindow.open = window.open

	$(iframeDocument).on 'click', 'a[href^="http"]', (e) ->
		url = $(this).attr('href')
		window.open(url, '_system')
		e.preventDefault()

	iframe.contentWindow.addEventListener 'onNewVersion', (e) ->
		if Servers.getActiveServer().info.version is e.detail
			return

		if not confirm('There is a new version available, do you want to update now?')
			return

		$(document.body).addClass 'loading'
		$('.loading-text').text 'Updating files...'
		serverAddress = Servers.getActiveServer().url
		name = Servers.getActiveServer().name
		Servers.updateServer serverAddress, (status) ->
			if status.done is true
				$('.loading-text').text "Loading #{name}..."
				Servers.save()
				Servers.startServer serverAddress, ->
					showView 'server'
			else
				$('.loading-text').html "Updating files...<br/>( #{status.count} / #{status.total} )"

	started = undefined

	addSwipeEventToOpenServerList iframeDocument

	url = Servers.getActiveServer().url

	# Save all localStorage records from inframe in the main
	# localStorage as an objetc of key:value under the key (url)
	iframe.contentWindow.localStorage.setItem = (key, value) ->
		data = JSON.parse localStorage.getItem(url) or '{}'
		data[key] = value
		localStorage.setItem url, JSON.stringify(data)

	# Respond inframe localStorage from the main localStorage
	# getting from the server object
	iframe.contentWindow.localStorage.getItem = (key) ->
		data = JSON.parse localStorage.getItem(url) or '{}'
		return data[key]


onServerClick = (e) ->
	toggleServerList(false)
	target = $(e.currentTarget)
	$(document.body).addClass 'loading'
	$('.loading-text').text "Loading #{target.data('name')}..."
	setTimeout ->
		showView 'server'
		Servers.startServer target.data('url'), ->
			Servers.setActiveServer target.data('url')
	, 200


onServerDeleteClick = (e) ->
	target = $(e.currentTarget)
	if confirm("Delete server #{target.data('name')}")
		activeServer = Servers.getActiveServer()
		Servers.deleteServer target.data('url')
		if activeServer.url is target.data('url')
			toggleServerList(false)
			setTimeout ->
				refreshServerList()
				showView 'start'
			, 200
		else
			refreshServerList()


onAddServerClick = ->
	toggleServerList(false)
	setTimeout ->
		showView 'start'
	, 200


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


window.addEventListener 'native.keyboardshow', (e) ->
	if device?.platform.toLowerCase() isnt 'android'
		$('.keyboard').css 'bottom', e.keyboardHeight


window.addEventListener 'native.keyboardhide', ->
	if device?.platform.toLowerCase() isnt 'android'
		$('.keyboard').css 'bottom', 0


document.addEventListener 'pause', (e) ->
	$('iframe')[0].contentDocument.dispatchEvent(e)


document.addEventListener 'resume', (e) ->
	$('iframe')[0].contentDocument.dispatchEvent(e)


document.addEventListener "deviceready", ->
	cordova.plugins?.Keyboard?.hideKeyboardAccessoryBar? true
	cordova.plugins?.Keyboard?.disableScroll? true

	refreshServerList()

	$('form').on 'submit', (e) ->
		e.preventDefault()
		cordova.plugins.Keyboard.close()
		setTimeout ->
			registerServer()
		, 100

	$(document).on 'click', '.server .name', onServerClick
	$(document).on 'click', '.server .delete-btn', onServerDeleteClick
	$(document).on 'click', '.addServer', onAddServerClick

	$(document).on 'click', "#serverList", (e) ->
		if $(e.target).is('#serverList')
			toggleServerList(false)

	$(document).on 'click', ".overlay", (e) ->
		if $(e.target).is('.overlay')
			toggleServerList(false)

	$('iframe').on 'load', onIframeLoad
	$('#serverAddress').on 'input', serverAddressInput

	addSwipeEventToOpenServerList $('#startView')

	activeServer = Servers.getActiveServer()
	if activeServer?
		$(document.body).addClass 'loading'
		$('.loading-text').text "Loading #{activeServer.name}..."
		Servers.startServer activeServer.url, (err, url) ->
			if err?
				# TODO err
				return console.log err

			showView 'server'

	navigator.splashscreen.hide()
