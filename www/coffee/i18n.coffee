window.languages = {}

window.loadI18nLanguage = (language, cb) ->
	url = "shared/i18n/#{language}.i18n.json"
	if location.protocol is 'http:'
		url = '/' + url

	request = $.getJSON url
	request.done (data) ->
		window.languages[language] = data
		cb? null, data

	request.fail (err) ->
		cb? err

language = navigator.language.split('-').shift()

window.loadI18n = (cb) ->
	loadI18nLanguage 'en', ->
		if not window.languages[language]?
			loadI18nLanguage language, cb
		else
			cb()

window.cordovai18n = (string, args...) ->
	if not string?
		return

	if window.languages[language]?[string]?
		string = window.languages[language][string]
	else if window.languages.en?[string]?
		string = window.languages.en[string]

	while string.indexOf('%s') > -1
		string = string.replace '%s', args.shift()

	return string

loaded = false
window.addEventListener 'load', ->
	loaded = true

window.updateHtml = ->
	for item in $('[data-i18n]')
		item.innerHTML = cordovai18n $(item).data('i18n')

loadI18n ->
	if loaded is true
		updateHtml()
	else
		window.addEventListener 'load', ->
			updateHtml()
