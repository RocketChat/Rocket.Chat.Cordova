window.languages = {}

window.loadI18nLanguage = (language, cb) ->
	request = $.getJSON "i18n/#{language}.i18n.json"
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

window.__ = (string) ->
	if window.languages[language]?[string]?
		return window.languages[language][string]
	if window.languages.en?[string]?
		return window.languages[language][string]
	return string

loaded = false
window.addEventListener 'load', ->
	loaded = true

window.updateHtml = ->
	for item in $('[data-i18n]')
		item.innerHTML = __ $(item).data('i18n')

loadI18n ->
	if loaded is true
		updateHtml()
	else
		window.addEventListener 'load', ->
			updateHtml()
