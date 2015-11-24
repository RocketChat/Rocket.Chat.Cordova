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
				<div class="toggle">Server List</div>
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
	$('.loading-text').text "Loading #{target.data('name')}..."
	setTimeout ->
		Servers.setActiveServer target.data('url')
		Servers.startServer target.data('url'), ->
			#
	, 200


onServerDeleteClick = (e) ->
	target = $(e.currentTarget)
	if confirm("Delete server #{target.data('name')}")
		activeServer = Servers.getActiveServer()
		Servers.deleteServer target.data('url'), ->
			if activeServer.url is target.data('url')
				onAddServerClick()
			else
				refreshServerList()


onAddServerClick = ->
	# location.href = cordova.file.applicationDirectory + 'www/index.html'
	location.href = "cdvfile://localhost/bundle/www/index.html?addServer"


window.addEventListener "onNewVersion", (e) ->
	url = Meteor.absoluteUrl().replace(/\/$/, '')
	version = e.detail

	server = Servers.getServer url

	if not server?
		return

	if server.info.version is version
		return

	if not confirm('There is a new version available, do you want to update now?')
		return

	location.href = "cdvfile://localhost/bundle/www/index.html?updateServer=#{encodeURIComponent(url)}&version=#{encodeURIComponent(version)}"


document.addEventListener "deviceready", ->
	Servers.onLoad ->
		refreshServerList()

	$(document).on 'click', '#serverList .server .name', onServerClick
	$(document).on 'click', '#serverList .server .delete-btn', onServerDeleteClick
	$(document).on 'click', '#serverList .addServer', onAddServerClick

	$(document).on 'click', "#serverList", (e) ->
		if $(e.target).is('#serverList')
			toggleServerList(false)

	addSwipeEventToOpenServerList $(document)
