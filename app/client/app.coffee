
# A very ugly set of functions that gives us an idea
# of what time it will be when a message reaches the server
window.$now = Date.now or -> new Date().getTime()
syncClock = (sampleSize, cb) ->
	_sc = (summOffs, times) ->
		SS.server.app.calcOffset $now(), (offs) ->
				if times > 1
					sc = ->
						_sc offs + summOffs, times - 1, cb
					setTimeout sc, 2000
				else
					avgOffset = (offs + summOffs) / sampleSize
					C.app.serverNow = ->
						$now() + avgOffset
					cb()
	
	_sc(0, sampleSize)


exports.user_id = Math.random().toString(36).substring(7)

generateColor = ->
	rn = Math.random() * 73
	gn = Math.random() * 73
	bn = 123 - rn - gn 
	colors = for c in [rn, gn, bn]
		(182 + c).toString(16).substring 0, 2
	return '#' + colors.join ''

#generateColor = ->
#	rn = Math.random() * 127
#	gn = Math.random() * 127
#
#	bn = 381 - rn - gn 
#	colors = for c in [rn, gn, bn]
#		(63 + c).toString(16).substring 0, 2
#	return '#' + colors.join ''

showOptions = ->
	$('#showoptions').slideUp()
	$('#options').slideDown()
	$('#message').slideDown()
	false

hideOptions = ->
	$('#showoptions').slideDown()
	$('#options').fadeOut()
	$('#message').fadeOut()
	#$('#solink').click showOptions
	false


# This method is called automatically when the websocket connection is established.
exports.init = ->
	window.C = SS.client
	$('#solink').click showOptions
	$('#holink').click hideOptions
	syncClock 1, ->	
		C.app.socket_id = SS.socket.socket.sessionid
		SS.server.app.getAuthor (author) ->
			if author
				C.app.user_id = author.user_id
			else
				SS.server.app.setAuthor
					'user_id': C.app.user_id
					'color':   generateColor()
				# new C.modals.LoginDiag()

		C.app.route = new C.app.Router()
		unless Backbone.history.start {pushState: true}
			SS.server.app.newDocID (docid) ->
				C.app.route.navigate "doc/" + docid, true

		$('#modes').change ->
			mode = $('#modes').val()
			#C.app.text.view.setMode mode
			C.app.route.navigate 'doc/' + C.app.text.id + '?mode=' + mode, {trigger:true}

		$('#themes').change ->
			colors = $('#themes').val()
			#C.app.text.view.setMode mode
			C.app.text.view.setTheme colors
			# todo set session preference

		runSync = ->
			syncClock 5, -> console.log 'synced clock'
		setInterval runSync, 1000000
		runSync()
	
	for mode in C.views.availableModes
		$('#modes').append '<option value="' + mode + '"> ' + mode + '</option>'
	


class exports.Router extends Backbone.Router
	routes:
		"doc/:id?mode=:lang": "setMode"
		"doc/:id":            "setDoc"

	setMode: (id, lang) =>
		@loadDoc id, ->
			if C.app.text.view.setMode(lang) and $('#modes').val() isnt lang
				$('#modes').val lang

	setDoc: (id) =>
		@navigate 'doc/' + id + '?mode=null', {trigger:true}



	loadDoc: (id, cb) =>
		unless C.app.text? and C.app.text.id is id
			SS.server.app.loadDoc id, (chars, authors) ->
				# todo: race conditions if someone is
				# fervuously typing from the start
				SS.events.on 'newChange', (change, channel) ->
					if channel is id
						C.app.text.theirChange change
				C.app.text = new C.models.SCText chars,
					'id':id
					'authors':authors

				SS.events.on 'authorOnline', C.app.text.addAuthor
				
				authorOnline = ->
					SS.server.app.authorOnline C.app.text.id

				authorOnline()	
				setInterval authorOnline, 30000

				if cb?
					cb(C.app.text)
		else if cb?
			cb C.app.text
