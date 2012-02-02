# Server-side Code

textID2RedisKey = (id) ->
	"snucode:doc:" + id

createDocID = (cb) ->
	id = Math.random().toString(36).substring(7)
	R.exists textID2RedisKey id, (err, exists) ->
		if exists
			createDocID cb
		else
			# todo: this does not create a new document
			# so there could be race conditions
			cb id


exports.actions =
	pushChange: (change, cb) ->
		change.socket_id = @request.socket_id
		SS.publish.channel [change.textID], 'newChange', change
		
		redis_args = [textID2RedisKey(change.textID)]
		for addC in change.addChars
			redis_args.push addC.place
			redis_args.push addC.id

		R.zadd redis_args, ->
			redis_args = [textID2RedisKey(change.textID)]
			R.zrem redis_args.concat(change.removeCharIDs), ->
					cb()

		

	newDocID: (cb) ->
		createDocID cb

	loadDoc: (id, cb) ->
		@session.channel.subscribe(id) 
		R.zrange textID2RedisKey(id), 0,-1,"withscores", (err, pchars) ->
			chars = []
			while pchars.length > 0
				p = pchars.pop()
				id = pchars.pop()
				val = id[id.length-1]
				chars.push
					'value': val
					'id': id
					'place': parseFloat(p)
					
			cb chars
	
	calcOffset: (clientTime, cb) ->
		# todo: check whether it's Date.now
		cb Date.now() - clientTime
	
