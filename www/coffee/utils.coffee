window.listDirectory = (url, options, cb) ->
	if typeof options is 'function'
		cb = options
		options = {}

	fail = (err) ->
		# cb(err)

	resolveSuccess = (entry) ->
		readEntriesSuccess = (entries) ->
			window.entries = entries
			names = []
			for entry in entries
				names.push entry.name
				console.log entry.name
			# cb null, names

		reader = entry.createReader()
		reader.readEntries readEntriesSuccess, fail

	window.resolveLocalFileSystemURL url, resolveSuccess, fail


window.writeFile = (directoryPath, fileName, content, cb) ->
	fail = (err) ->
		cb err, null

	resolveSuccess = (dirEntry) ->
		getFileSuccess = (fileEntry) ->
			createWriterSuccess = (writer) ->
				writer.onwrite = (evt, a) ->
					cb null, evt.target.result

				writer.onerror = fail
				writer.write content

			fileEntry.createWriter createWriterSuccess, fail

		getFileOptions =
			create: true
			exclusive: false

		dirEntry.getFile fileName, getFileOptions, getFileSuccess, fail

	window.resolveLocalFileSystemURL directoryPath, resolveSuccess, fail


window.writeDir = (directoryPath, dirName, cb) ->
	fail = (err) ->
		cb err, null

	resolveSuccess = (dirEntry) ->
		getDirectorySuccess = (fileEntry) ->
			console.log('created')

		dirEntry.getDirectory dirName, {create: true}, getDirectorySuccess, fail

	window.resolveLocalFileSystemURL directoryPath, resolveSuccess, fail


window.removeDir = (directoryPath, cb) ->
	fail = (err) ->
		cb err, null

	resolveSuccess = (dirEntry) ->
		removeRecursivelySuccess = ->
			console.log('Directory removed')

		dirEntry.removeRecursively removeRecursivelySuccess, fail

	window.resolveLocalFileSystemURL directoryPath, resolveSuccess, fail
