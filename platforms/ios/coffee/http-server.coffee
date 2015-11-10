window.startServer = (wwwroot) ->
	if not httpd?
		return console.log 'CorHttpd plugin not available/ready.'

	getURLSuccess = (url) ->
		console.log 'getURLSuccess', url

		if url.length > 0
			# document.getElementById('url').innerHTML = "server is up: <a href='" + url + "' target='_blank'>" + url + "</a>";
			console.log "server is up:", url
		else
			options =
				'www_root': wwwroot
				'port': 8080

			success = (url) ->
				console.log "server is started:", url
				# updateStatus()

			failure = (error) ->
				# document.getElementById('url').innerHTML = 'failed to start server: ' + error
				console.log 'failed to start server:', error

			httpd.startServer options, success, failure

	getURLFailure = () ->
		console.log 'getURLFailure', arguments

	httpd.getURL getURLSuccess, getURLFailure
