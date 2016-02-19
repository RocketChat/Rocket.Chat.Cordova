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


window.readFile = (directoryPath, fileName, cb) ->
	fail = (err) ->
		cb err, null

	resolveSuccess = (dirEntry) ->
		getFileSuccess = (fileEntry) ->
			fileSuccess = (file) ->
				reader = new FileReader()

				reader.onloadend = (e) ->
					cb null, this.result

				reader.readAsText file

			fileEntry.file fileSuccess, fail

		dirEntry.getFile fileName, {}, getFileSuccess, fail

	window.resolveLocalFileSystemURL directoryPath, resolveSuccess, fail

window.removeFile = (directoryPath, fileName, cb) ->
	resolveSuccess = (dirEntry) ->
		getFileSuccess = (fileEntry) ->
			fileEntry.remove cb

		dirEntry.getFile fileName, {}, getFileSuccess

	window.resolveLocalFileSystemURL directoryPath, resolveSuccess

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


window.ensurePath = (path, cb) ->
	fail = (err) ->
		console.log err
		cb()

	createDir = (parent, folders) ->
		getDirectorySuccess = (dirEntry) ->
			folders.shift()
			if folders.length > 0
				createDir dirEntry, folders
			else
				cb()

		parent.getDirectory folders[0], {create: true}, getDirectorySuccess, fail

	window.resolveLocalFileSystemURL cordova.file.dataDirectory, (dirEntry) ->
		createDir dirEntry, path.split('/')
	, fail


window.copyFile = (src, dest, cb) ->
	dest = dest.split '/'

	destName = dest.pop()
	destPath = dest.join '/'

	fail = (desc) ->
		return (err) ->
			console.log err, desc, src, destPath, destName
			cb()

	resolveSrcSuccess = (srcEntry) ->
		resolveDestSuccess = (destDirEntry) ->

			copyFile = ->
				copyToSuccess = ->
					console.log 'copied', destPath, destName
					cb()
				srcEntry.copyTo destDirEntry, destName, copyToSuccess, fail('copy')

			getFileSuccess = (fileEntry) ->
				fileEntry.remove()
				copyFile()

			getFileFail = ->
				copyFile()

			destDirEntry.getFile destName, {}, getFileSuccess, getFileFail

		ensurePath destPath, ->
			window.resolveLocalFileSystemURL cordova.file.dataDirectory + destPath, resolveDestSuccess, fail('dest')

	window.resolveLocalFileSystemURL src, resolveSrcSuccess, fail('src')
