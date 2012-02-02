class exports.SCTextView extends Backbone.View
	initialize: ->
		@mode = "javascript"
		@calcByLine()
		# todo: bind to change events in model
		@render()

	render: =>
		@cm = CodeMirror document.body, 
			value: @model.getText()
			lineNumbers: true
			#'mode': @mode
			'onChange': @onChange


	pos2model: (cmpos) =>
		# format {ch:0, line:18}
		@byLine[cmpos.line][cmpos.ch]

	pos2index: (cmpos) =>
		@lineIndex[cmpos.line] + cmpos.ch
	
	index2pos: (index) =>
		line = 0
		while @lineIndex[line] + @byLine[line].length < index
			line += 1

		{'line': line, ch: index - @lineIndex[line]}

	insertChar: (c, options) =>
		index = @model.indexOf c
		pos = @index2pos index

		if c.get('value') is '\n'
			line = @byLine[pos.line]
			newline = line.splice pos.ch, line.length
			@byLine.splice pos.line+1, 0, newline

			l = line.length - newline.length + 1
			@lineIndex.splice pos.line+1, 0, @lineIndex[pos.line] + l
			@adjustLI pos.line+1, 1
		else
			@byLine[pos.line].splice pos.ch, 0, c
			@adjustLI pos.line, 1

		@cm.replaceRange c.get('value'), pos, pos, options

	removeChar: (c) =>
		index = @model.indexOf c
		pos = @index2pos index

		@byLine[pos.line].splice pos.ch, 1
		@adjustLI pos.line, -1

		pos1 = {'line': pos.line, 'ch': pos.ch + 1}

		@cm.replaceRange '', pos, pos1, options


	onChange: (editor, change) =>
		change.timestamp = C.app.serverNow()
		# todo:
			# queue changes until byline is done updating
			# to new editor state 
		# change has values: {from, to, text, next}

		change.fi =  @pos2index change.from
		change.ti =  @pos2index change.to

		@model.myChange change, {silent: true}

		@updateByLine change

		# todo check when this even happens and how order affects it!!
		if change.next?
			console.log "we actually have another change"
			console.log change.next
			@onChange editor, change.next

	
	updateByLine: (change) =>
		# change now contains addChars and removeCharIDs

		# first remove chars:
		removeLen = change.removeCharIDs.length
		lineI = change.from.line
		charI = change.from.ch
		removedChars = []

		while removedChars.length < removeLen
			removedChars = @byLine[lineI].splice(charI,removeLen)
			removeLen -= removedChars.length # todo: account for newline

			if @byLine[lineI].length is 0
				@byLine.splice lineI, 1
				removeLen -= 1
				@lineIndex.splice lineI, 1
				@adjustLI lineI-1, 0 - removeLen
			else
				@adjustLI lineI, 0 - removLen
			lineI += 1

		# then add chars:
		lineI = change.from.line
		charI = change.from.ch
		addCharI = 0

		for c in change.addCharModels.slice(addCharI, addCharI + change.text[0].length)
			@byLine[lineI].splice charI, 0, c
			charI += 1

		# store the endslice that gets moved by editing
		endslice = []
		if charI + 1 < @byLine[lineI].length
			endslice = @byLine[lineI].splice charI, @byLine[lineI].length - charI	

		# adjust line index
		@adjustLI lineI, change.text[0].length - endslice.length

		# add further lines
		addCharI += change.text[0].length + 1 # account for newline
		for line in change.text[1...change.text.length]
			lineI += 1
			@byLine.splice lineI, 0, change.addCharModels.slice(addCharI, addCharI + line.length)
			addCharI += line.length + 1 # account for any newline

			#initialize a new lineIndex
			@lineIndex.splice lineI, 0, @lineIndex[lineI-1] + @byLine[lineI-1].length
			@adjustLI lineI, line.length

		@byLine[lineI] = @byLine[lineI].concat endslice

		@adjustLI lineI, endslice.length

	adjustLI: (index, amount) =>
		# adjust starting with the next index
		# so indexes increase after changed line
		unless index+1 >= @lineIndex.length
			@lineIndex[index+1] = @lineIndex[index]
		for line in [index+1 ... @lineIndex.length]
			@lineIndex[line] += amount

	calcByLine: =>
		# todo: queue?

		ar = @model.toArray()

		# retrieve the text from the model array 
		# (basically like with pluck, just not prone to changes) 
		art = _.map ar, (item) ->
			item.get "value"
		txt = art.join ""

		lines = txt.split '\n'
		bl = []
		li = []
		lstart = 0
		# store lines as slices of the model collection
		for i in [0 ... lines.length]
			li.push lstart
			lend = lstart + lines[i].length
			bl.push ar.slice lstart, lend
			lstart = lend + 1

		#li.push li[li.length-1] + bl[bl.length-1].length
		@byLine = bl
		@lineIndex = li
