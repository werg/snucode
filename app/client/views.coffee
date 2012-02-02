class exports.SCTextView extends Backbone.View
	initialize: ->
		@mode = "javascript"
		@calcLineIndex()
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
		@model.at @pos2index cmpos

	pos2index: (cmpos) =>
		@lineIndex[cmpos.line] + cmpos.ch
	
	index2pos: (index) =>
		# indices of newline-characters
		# are at the end of the old line
		line = 0
		# check whether next line is 
		while @lineIndex[line+1]? and @lineIndex[line+1] <= index
			line += 1

		{'line': line, ch: index - @lineIndex[line]}

	insertChar: (c, options) =>
		index = @model.indexOf c
		pos = @index2pos index

		if c.get('value') is '\n'
			@lineIndex.splice pos.line+1, 0, index

		@adjustLI pos.line, 1
		@cm.replaceRange c.get('value'), pos, pos, options

	removeChar: (c, options) =>
		cmodel = @model.get c
		index = @model.indexOf cmodel
		pos = @index2pos index
		line1 = pos.line
		ch1 = pos.ch+1

		if cmodel.get('value') is '\n'
			@lineIndex.splice pos.line+1, 1
			line1 += 1
			ch1 = 0

		@adjustLI pos.line, -1
		pos1 = {'line': line1, 'ch': ch1}

		@cm.replaceRange '', pos, pos1, options


	onChange: (editor, change) =>
		change.timestamp = C.app.serverNow()
		# change has values: {from, to, text, next}

		change.fi =  @pos2index change.from
		change.ti =  @pos2index change.to

		@model.myChange change, {silent: true}

		@calcLineIndex()

		# todo check when this even happens and how order affects it!!
		if change.next?
			console.log "we actually have another change"
			console.log change.next
			@onChange editor, change.next


	calcLineIndex: =>
		li = [0]
		@model.forEach (c, index) =>
			if c.get('value') is '\n'
				li.push index+1

		@lineIndex = li

	adjustLI: (index, amount) =>
		# adjust starting with the next index
		# so indexes increase after changed line
		#if index+1 >= @lineIndex.length
		#	@lineIndex[index+1] = @lineIndex[index]
		for line in [index+1 ... @lineIndex.length]
			@lineIndex[line] += amount
