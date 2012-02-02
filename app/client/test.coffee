tests =




exports.runTest = ->
	for name, spec in tests
		result = spec()
		ok = if result
			": ok"
		else
			": fail!"
		console.log "running " + name + ok
		console.log result
