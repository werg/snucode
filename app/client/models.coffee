genCharID = (c, serverTS) ->
	randid = Math.random().toString(36).substring(7)
	return [serverTS, SS.client.app.user_id, randid, c].join ':'

class exports.Char extends Backbone.Model
	initialize: ->



class exports.SCText extends Backbone.Collection
	initialize: (models, options) ->
		@textChanged = true
		@id = options.id
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
			for r in change.removeCharIDs
				@view.removeChar r, {silent: true}
				@remove r

			change.removeCharIDs = []
			@storeChange change, options
			# change.addCharModels gets added in above function call
			for a in change.addCharModels
				@view.insertChar a, {silent: true}

	myChange: (change, options) =>
		# todo a queue system?
		fi = change.fi
		ti = change.ti

		change.removeCharModels = @models.slice(fi, ti)

		wholetext = change.text.join '\n'
		l = wholetext.length

		start = if fi > 0
				@at(fi-1).get 'place'
			else
				0.0

		end = if ti < @size() - 1 and @size() > 0
			@at(ti).get 'place'
		else
			1.0

		placeinc = 0.1 * (end - start) / l
		place = start + 0.5 * placeinc
		change.addChars = []

		for c in wholetext
			cobj = 
				'id': genCharID c, change.timestamp # todo add now
				'place': place
				'value': c
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

