
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


exports.user_id = "werg"

# This method is called automatically when the websocket connection is established.
exports.init = ->
	window.C = SS.client
	syncClock 1, ->		
		C.app.socket_id = SS.socket.socket.sessionid

		C.app.route = new C.app.Router()
		unless Backbone.history.start {pushState: true}
			SS.server.app.newDocID (docid) ->
				C.app.route.navigate "doc/" + docid, true

		runSync = ->
			syncClock 5, -> console.log 'synced clock'
		setInterval runSync, 1000000
		runSync()




class exports.Router extends Backbone.Router
	routes:
		"doc/:id":        "loadDoc"

	loadDoc: (id) =>
		SS.server.app.loadDoc id, (chars) ->
			# todo: race conditions if someone is
			# fervuously typing 
			SS.events.on 'newChange', (change) ->
				C.app.text.theirChange change
			C.app.text = new C.models.SCText chars, {'id':id}
