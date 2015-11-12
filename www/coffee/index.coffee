showView = (view) ->
	$('.view').addClass 'hidden'

	$('#' + view + 'View').removeClass 'hidden'


toggleServerList = (open) ->
	if open is true
		$('#serverList').addClass 'server-list-open'
	else if open is false
		$('#serverList').removeClass 'server-list-open'
	else
		$('#serverList').toggleClass 'server-list-open'


window.refreshServerList = ->
	ul = document.querySelector("#serverList ul")

	while ul.children[0]
		ul.children[0].remove()

	i = 0
	for server in Servers.getServers()
		li = document.createElement('LI')

		li.dataset.name = ++i
		li.dataset.url = server.url
		li.className = 'server'

		li.innerText = i

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

	$('.server', document).on 'click', (e) ->
		showView 'server'
		toggleServerList(false)
		target = $(e.currentTarget)
		Servers.startServer target.data('url')

	$('.addServer', document).on 'click', ->
		showView 'start'
		toggleServerList(false)
