addSwipeEventToOpenServerList = ($el) ->
	started = undefined

	$el.on 'touchstart', (e) ->
		if e.originalEvent.touches.length >= 2
			e.preventDefault()
			started =
				date: Date.now()
				pageX: e.originalEvent.touches[0].pageX
				pageY: e.originalEvent.touches[0].pageY

	$el.on 'touchmove', (e) ->
		if started?
			e.preventDefault()
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
	navigator.appInfo.getAppInfo (appInfo) ->
		serverList = document.querySelector("#serverList")

		if not serverList?
			$(document.body).on 'click', '#serverList .toggle', ->
				$('#serverList .panels').toggleClass('rotate')

		serverList?.remove()
		overlay = document.querySelector(".server-list-overlay")
		overlay?.remove()

		serverList = """
			<div id="serverList">
				<div class="panels">
					<div class="panel">
						<div class="toggle">#{cordovai18n('Server_List')}</div>
						<ul>
						</ul>
					</div>
					<div class="panel back">
						<div class="toggle">#{cordovai18n('Information')}</div>
						<ul>
							<li>Version: <span style="float: right;">#{appInfo.version}</span></li>
							<li>Build: <span style="float: right;">#{appInfo.build}</span></li>
						</ul>
					</div>
				</div>
			</div>
		"""

		document.body.appendChild $('<div class="server-list-overlay"></div>')[0]
		document.body.appendChild $(serverList)[0]
		ul = document.querySelector("#serverList ul")

		for server in Servers.getServers()
			li = """
				<li class="server">
					<div data-name="#{server.name}" data-url="#{server.url}" class="name">#{server.name}</div>
					<div data-name="#{server.name}" data-url="#{server.url}" class="delete-btn">
						<svg aria-hidden="true" role="img" version="1.1" viewBox="0 0 360 360" style="width: 100%; height: 100%;">
							<path fill="#C31919" d="M180.224,0C80.689,0,0,80.689,0,180.223c0,99.535,80.689,180.225,180.224,180.225 c99.536,0,180.225-80.689,180.225-180.225C360.449,80.689,279.759,0,180.224,0z M253.953,196.608H106.496V163.84h147.457V196.608z"></path>
						</svg>
					</div>
				</li>
			"""
			ul.appendChild $(li)[0]

		li = """
			<li class="addServer">
				<div class="name"></div>
				<div class="add-btn">
					<svg aria-hidden="true" role="img" version="1.1" viewBox="0 0 360 360" style="width: 100%; height: 100%;">
						<path fill="#19C319" d="M180.224,0C80.689,0,0,80.689,0,180.223c0,99.535,80.689,180.225,180.224,180.225 c99.536,0,180.225-80.689,180.225-180.225C360.449,80.689,279.759,0,180.224,0z M253.953,196.608h-57.344v57.343h-32.768v-57.343 h-57.345V163.84h57.345v-57.344h32.768v57.344h57.344V196.608z"></path>
					</svg>
				</div>
			</li>
		"""
		ul.appendChild $(li)[0]


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
			if buttonIndex is 1
				Servers.startLocalServer window.urlToUpdate

			window.urlToUpdate = undefined

		if not window.urlToUpdate?
			navigator.notification.confirm cordovai18n("There_is_a_new_version_available_do_you_want_to_update_now_question"), onConfirm, cordovai18n("New_version"), [cordovai18n("Update"), cordovai18n("Cancel")]

		window.urlToUpdate = "index.html?updateServer=#{encodeURIComponent(url)}&version=#{encodeURIComponent(version)}"


document.addEventListener "deviceready", ->
	# if device.platform.toLowerCase() is 'ios'
	# 	cordova.plugins.iosrtc.registerGlobals()

	Servers.onLoad ->
		refreshServerList()

	$(document).on 'click', '#serverList .server .name', onServerClick
	$(document).on 'click', '#serverList .server .delete-btn', onServerDeleteClick
	$(document).on 'click', '#serverList .addServer', onAddServerClick

	$(document).on 'click', "#serverList:not(.toggle)", (e) ->
		if $(e.target).is('#serverList')
			toggleServerList(false)

	document.addEventListener 'click', (e) ->
		if e.target.nodeName is 'A' and e.target.getAttribute('href') is '#'
			e.stopPropagation()
			e.preventDefault()

	addSwipeEventToOpenServerList $(document)

	ThreeDeeTouch.onHomeIconPressed = (payload) ->
		navigator.splashscreen.show()

		Servers.onLoad ->
			if payload.type is 'new'
				window.AUTOLOAD = false
				navigator.splashscreen.hide()
				return Servers.startLocalServer "index.html?addServer"

			host = payload.type.replace /\/$/, ''
			if Servers.serverExists(host) isnt true
				navigator.splashscreen.hide()
				return

			activeServer = Servers.getActiveServer()
			if activeServer? and activeServer.url is host and window.Meteor?
				navigator.splashscreen.hide()
				return

			window.AUTOLOAD = false
			navigator.splashscreen.hide()
			Servers.startServer host, (err, url) ->
				if err?
					# TODO err
					return console.log err
