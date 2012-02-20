# Server-side Code

textID2RedisKey = (id) ->
	"snucode:doc:" + id

createDocID = (cb) ->
	id = Math.random().toString(36).substring(7)
	R.exists textID2RedisKey(id), (err, exists) ->
		if exists
			createDocID cb
		else
			# todo: this does not create a new document
			# so there could be race conditions
			cb id

validColor = (color) ->
	numval = parseInt color.substring(1), 16
	color[0] is '#' and numval < 16777216 and numval >= 0

validUserID = (user_id) ->
	result = true
	for c in user_id.toLowerCase().split()
		result = result and not isNaN parseInt c, 36
	return result

validAuthor = (author) ->
	validColor(author.color) and validUserID(author.user_id)

setColor = (author, textID, cb) ->
	colorKey = textID2RedisKey(textID) + ':colors'
	R.hset colorKey, author.user_id, author.color, cb


exports.actions =
	pushChange: (change, cb) ->
		change.socket_id = @request.socket_id
		SS.publish.channel [change.textID], 'newChange', change
		
		color = @session.attributes.author.color
		user_id = @session.attributes.author.user_id
		rid = textID2RedisKey(change.textID)

		redis_args = [rid]
		for addC in change.addChars
			redis_args.push addC.place
			redis_args.push addC.id

		R.zadd redis_args, ->
			redis_args = [rid]
			R.zrem redis_args.concat(change.removeCharIDs), ->
				R.hset rid + ':color', user_id, color, ->
					cb()

	setAuthor: (author, cb) ->
		if validAuthor(author)
			unless @session.attributes?
				@session.attributes = {}
			@session.attributes.author = author
			@session.save ->
				cb true
		else
			cb false

	getAuthor: (cb) ->
		if @session.attributes.author?
			cb @session.attributes.author
		else
			cb false

	setColor: (textID, cb) ->
		setColor @session.attributes.author, textID, cb
		# to do broadcast some kind of color change message?


	authorOnline: (textID, cb) ->
		if @session.attributes.author?
			SS.publish.channel [textID], 'authorOnline', @session.attributes.author
		cb()

	newDocID: (cb) ->
		createDocID cb

	loadDoc: (id, cb) ->
		#@session.channel.unsubscribeAll()
		@session.channel.subscribe(id)
		docID = textID2RedisKey(id)

		# delete document after two weeks
		R.expire docID, 1209600
		R.expire docID + ':authors', 1209600

		# retrieve doc
		R.zrange docID, 0,-1,"withscores", (err, pchars) ->
			chars = []
			while pchars.length > 0
				p = pchars.pop()
				id = pchars.pop()
				val = id[id.length-1]
				auth = id.split(':')[1]
				chars.push
					'value': val
					'id': id
					'place': parseFloat(p)
					'author': auth
			
			R.hgetall docID + ':authors', (authors) ->
				cb chars, authors
	
	calcOffset: (clientTime, cb) ->
		# todo: check whether it's Date.now
		cb Date.now() - clientTime
	
