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

		li.innerText = server.name.replace(/https?:\/\//, '')

		ul.appendChild li


	li = document.createElement('LI')

	li.className = 'addServer'
	li.innerText = '+'

	ul.appendChild li


registerServer = ->
	serverAddress = $('#serverAddress').val().trim()

	if serverAddress.length is 0
		serverAddress = 'https://demo.rocket.chat'

	Servers.registerServer serverAddress, serverAddress, ->
		refreshServerList()
		Servers.startServer serverAddress
		showView 'server'
		toggleServerList(false)


document.addEventListener "deviceready", ->
	refreshServerList()

	$('#serverAddressButton').on 'click', registerServer
	$("#serverList .toggle", document).on 'click', toggleServerList
	$(".overlay", document).on 'click', -> toggleServerList(false)

	$('.server', document).on 'click', (e) ->
		toggleServerList(false)
		target = $(e.currentTarget)
		setTimeout ->
			showView 'server'
			Servers.startServer target.data('url')
		, 200

	$('.addServer', document).on 'click', ->
		toggleServerList(false)
		setTimeout ->
			showView 'start'
		, 200

	# $('#startView').on('touchmove', function() {console.log(arguments)})
	mc = new Hammer.Manager $('#startView')[0]
	mc.add new Hammer.Swipe
		direction: Hammer.DIRECTION_UP
		pointers: 2

	mc.on "swipeup", ->
		toggleServerList()


	$('iframe').on 'load', ->
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


