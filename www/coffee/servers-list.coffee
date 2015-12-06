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
	serverList = document.querySelector("#serverList")
	serverList?.remove()

	serverList = """
		<div id="serverList">
			<div class="panel">
				<div class="toggle">#{cordovai18n('Server_List')}</div>
				<ul>
				</ul>
			</div>
		</div>
	"""

	document.body.appendChild $(serverList)[0]
	ul = document.querySelector("#serverList ul")

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


onServerClick = (e) ->
	toggleServerList(false)
	target = $(e.currentTarget)
	$(document.body).addClass 'loading'
	$('.loading-text').text cordovai18n("Loading_s", target.data('name'))
	setTimeout ->
		Servers.setActiveServer target.data('url')
		Servers.startServer target.data('url'), ->
			#
	, 200


onServerDeleteClick = (e) ->
	target = $(e.currentTarget)
	onConfirm = (buttonIndex) ->
		if buttonIndex isnt 1
			return

		activeServer = Servers.getActiveServer()
		Servers.deleteServer target.data('url'), ->
			if activeServer.url is target.data('url')
				onAddServerClick()
			else
				refreshServerList()

	navigator.notification.confirm cordovai18n("Delete_server_s_question", target.data('name')), onConfirm, cordovai18n("Warning"), [cordovai18n("Delete"), cordovai18n("Cancel")]


onAddServerClick = ->
	Servers.startLocalServer "index.html?addServer"


window.addEventListener "onNewVersion", (e) ->
	Servers.onLoad =>
		url = Meteor.absoluteUrl().replace(/\/$/, '')
		version = e.detail

		server = Servers.getServer url

		if not server?
			navigator.notification.alert cordovai18n("The_URL_configured_in_your_server_s_is_not_the_same_that_you_are_using_here", url), null, cordovai18n("Warning")
			return

		if server.info.version is version
			return

		onConfirm = (buttonIndex) ->
			if buttonIndex isnt 1
				return

			Servers.startLocalServer "index.html?updateServer=#{encodeURIComponent(url)}&version=#{encodeURIComponent(version)}"

		navigator.notification.confirm cordovai18n("There_is_a_new_version_available_do_you_want_to_update_now_question"), onConfirm, cordovai18n("New_version"), [cordovai18n("Update"), cordovai18n("Cancel")]


document.addEventListener "deviceready", ->
	# if device.platform.toLowerCase() is 'ios'
	# 	cordova.plugins.iosrtc.registerGlobals()

	Servers.onLoad ->
		refreshServerList()

	$(document).on 'click', '#serverList .server .name', onServerClick
	$(document).on 'click', '#serverList .server .delete-btn', onServerDeleteClick
	$(document).on 'click', '#serverList .addServer', onAddServerClick

	$(document).on 'click', "#serverList", (e) ->
		if $(e.target).is('#serverList')
			toggleServerList(false)

	addSwipeEventToOpenServerList $(document)
