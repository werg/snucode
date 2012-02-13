exports.availableModes = ["null", "clike", "clojure", "coffeescript", "css", "diff", "gfm", "groovy", "haskell", "htmlembedded", "htmlmixed", "javascript", "jinja2", "less", "lua", "markdown", "mysql", "ntriples", "pascal", "perl", "php", "plsql", "python", "r", "rst", "ruby", "rust", "scheme", "smalltalk", "sparql", "stex", "tiddlywiki", "velocity", "verilog", "xml", "xmlpure", "yaml"]

class exports.SCTextView extends Backbone.View
	initialize: ->
		@mode = "javascript"
		@calcLineIndex()
		# todo: bind to change events in model
		@render()

	render: =>
		@theme = $('#themes').val()
		@cm = CodeMirror document.getElementById('content'), 
			value: @model.getText()
			lineNumbers: true
			#'mode': @mode
			'onChange': @onChange
			'smartIndent': false
			#'theme': 'monokai'

		@setTheme @theme

	setTheme: (theme) =>
		@cm.setOption 'theme', theme
		$('body').removeClass 'cm-s-' + @theme
		@theme = theme
		$('body').addClass 'cm-s-' + @theme


	addAuthor: (author) =>
		style =  "<style type='text/css'> .cm-author-" + author.user_id + "{ border-color: " + author.color + "; border-bottom-style: dotted; border-width: 2px;} </style>"
		$(style).appendTo("head")

	setMode: (lang) =>
		if lang in C.views.availableModes
			@model.lang = lang
			CodeMirror.defineMode "concur_" + lang, (config, parserConfig) ->
				mode =
					startState: ->
						state = 
							index: 0
						return state
						
					token: (stream, state) ->
						textarea = C.app.text.view.cm.getValue().length
						backtext = C.app.text.size()

						if textarea is backtext
							# our model is up-to-date
							if state.index > backtext
								console.log "what's this?"
							cAt = C.app.text.at(state.index)
							unless cAt?
								console.log "what's that?"
							while cAt.get('value') is '\n'
								state.index += 1
								cAt = C.app.text.at(state.index)

							author = cAt.get 'author'
							while stream.peek() and cAt? and cAt.get('author') is author
								stream.next()
								state.index += 1
								cAt = C.app.text.at state.index
							return 'author-' + author

						else 
							console.log 'we are trying to tokenize, even though the model isnt up-to-date!'
							# so we are dealing with stuff we wrote ourselves
							#for i in [0...textarea-backtext]
							#	stream.next()
							#return 'author-' + C.app.user_id

					copyState: (state) ->
						return {index: state.index}


				return CodeMirror.overlayParser(CodeMirror.getMode(config, lang), mode, true)

			@cm.setOption 'mode', 'concur_' + lang
			return true

		else
			return false
			
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
