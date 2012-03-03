genCharID = (c, serverTS) ->
	randid = Math.random().toString(36).substring(7)
	return [serverTS, SS.client.app.user_id, randid, c].join(':')

class exports.Char extends Backbone.Model
	initialize: ->


class exports.SCText extends Backbone.Collection
	initialize: (models, options) ->
		@textChanged = true
		@id = options.id
		@authors = []
		for id, color of options.authors
			@addAuthor
				'user_id': id
				'color': color
		@view = new C.views.SCTextView {model: this}


	model: SS.client.models.Char

	comparator: (c)->
		c.get 'place'
	
	calcText: =>
		# todo check whether value is ok as kwd
		@text = @pluck("value").join ''
		@textChanged = false

	getText: =>
		if @textChanged
			@calcText()
		return @text

	addAuthor: (author) =>
		unless author.user_id in @authors
			@authors.push author.user_id
			@view.addAuthor author

	storeChange: (change, options) =>
		# in: a list of id's in change.removeCharIDs
		#     a list of JSON-structures in change.addChars
		#     a timestamp
		#     
		# create a new model with ID for every
		# entry in change.addChars
		# add all of them between

		change.addCharModels = for spec in change.addChars
			new C.models.Char spec, {collection: this}
		@add change.addCharModels, options

		@remove change.removeCharIDs, options

		@textChanged = true
		
	theirChange: (change, options) =>
		if change.socket_id isnt C.app.socket_id
			@view.removeChars change.removeCharIDs, {silent: true}
			@remove change.removeCharIDs, options
			#for r in change.removeCharIDs
			#	@remove r

			change.removeCharIDs = []
			@storeChange change, options
			# change.addCharModels gets added in above function call
			@view.insertChars change.addCharModels, {silent: true}

	myChange: (change, options) =>
		# todo a queue system?
		fi = change.fi
		ti = change.ti

		change.removeCharModels = @models.slice(fi, ti)

		wholetext = change.text.join '\n'
		l = wholetext.length + 1  #(plus one for jitter)

		l1 = ti - fi

		if l > 1200 or l1 > 1200
			alert "Unfortunately, snucode cannot yet handle inserting or removing that much text - we get all sorts of nasty behavior!"
			window.location.reload()

		start = if fi > 0
				@at(fi-1).get 'place'
			else
				0.0

		end = if ti < @size() - 1 and @size() > 0
			@at(ti).get 'place'
		else
			1.0

		placeinc = 0.08 * (end - start) / l
		place = start + 0.5 * placeinc + Math.random() * placeinc 
		change.addChars = []

		for c in wholetext
			cobj = 
				'id': genCharID c, change.timestamp # todo add now
				'place': place
				'value': c
				'author': C.app.user_id
			change.addChars.push cobj
			place += placeinc

		change.removeCharIDs = []

		for c in change.removeCharModels
			change.removeCharIDs.push c.id
	
		pushPackage =
			'addChars': change.addChars
			'removeCharIDs': change.removeCharIDs
			'socket_id': C.app.socket_id
			'textID': @id

		# todo: check whether ordering of the following matters:
		SS.server.app.pushChange pushPackage
		@storeChange change, options

