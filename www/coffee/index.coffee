showView = (view) ->
	$('.view').addClass 'hidden'

	$('#' + view + 'View').removeClass 'hidden'


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
		li = document.createElement('LI')

		li.dataset.name = server.name
		li.dataset.url = server.url
		li.className = 'server'

		li.innerText = server.name

		ul.appendChild li


	li = document.createElement('LI')

	li.className = 'addServer'
	li.innerText = '+'

	ul.appendChild li


registerServer = ->
	serverAddress = $('#serverAddress').val().trim().toLowerCase()

	if serverAddress.length is 0
		serverAddress = 'https://demo.rocket.chat'

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
					$('#serverAddressButton').prop 'disabled', true
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
	iframe = $($('iframe').contents()[0])

	started = undefined

	iframe.on 'touchstart', (e) ->
		if e.originalEvent.touches.length is 2
			started =
				date: Date.now()
				pageX: e.originalEvent.pageX
				pageY: e.originalEvent.pageY

	iframe.on 'touchend', (e) ->
		if started?
			if Date.now() - started.date < 1000
				if Math.abs(e.originalEvent.pageX - started.pageX) < 30
					if Math.abs(e.originalEvent.pageY - started.pageY) > 50
						toggleServerList()

		started = undefined


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
			$('#serverAddressButton').prop 'disabled', false
			$('#alert-messages').empty()
		, 1000

addAlert = (alertObj) ->
	if not _.isString(alertObj.type) or not _.isString(alertObj.message)
		console.warn 'The alertObj', alertObj, 'is not a valid alert object, requires both type and message properties'
		return

	$('#alert-messages').append "<div class='alert alert-#{alertObj.type}' role='alert'>#{alertObj.message}</div>"

window.addEventListener 'native.keyboardshow', (e) ->
	# if device?.platform.toLowerCase() isnt 'android'
	$('.keyboard').css 'bottom', e.keyboardHeight


window.addEventListener 'native.keyboardhide', ->
	# if device?.platform.toLowerCase() isnt 'android'
	$('.keyboard').css 'bottom', 0


document.addEventListener "deviceready", ->
	cordova.plugins?.Keyboard?.hideKeyboardAccessoryBar? true
	cordova.plugins?.Keyboard?.disableScroll? true

	refreshServerList()

	$('#serverAddressButton').on 'click', registerServer
	$('.server', document).on 'click', onServerClick
	$('.addServer', document).on 'click', onAddServerClick

	$("#serverList", document).on 'click', (e) ->
		if $(e.target).is('#serverList')
			toggleServerList(false)

	$(".overlay", document).on 'click', (e) ->
		if $(e.target).is('.overlay')
			toggleServerList(false)

	$('iframe').on 'load', onIframeLoad
	$('#serverAddress').on 'input', serverAddressInput

	mc = new Hammer.Manager $('#startView')[0]
	mc.add new Hammer.Swipe
		direction: Hammer.DIRECTION_UP
		pointers: 2

	mc.on "swipeup", ->
		toggleServerList()


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
