{ exec } = require 'child_process'

execHandle = (after) ->
	(err, stdout, stderr) ->
		console.log stdout + stderr
		throw err if err?
		after()

run = (command) ->
	(after) ->
		#console.log "RUNNING #{command}"
		exec command, execHandle after

clean =
	run 'rm -r js js-std'

lint =
	run 'coffeelint -f src/lintConfig.json src/*.coffee'


compile_compiler =
	run 'coffee  --compile --bare --map --output js src'

compile_main =
	# compile_compiler
	run 'bin/smith --in std --out js-std --just Main.smith --is-std'

compile_smith =
	# compile_compiler
	run 'bin/smith --in std --out js-std --quiet --is-std'

run_smith =
	# compile_smith
	run 'node --harmony js-std/run.js'

test =
	'node --harmony js/test.js'

watch =
	# compile_compiler
	'bin/smith --in std --out js-std --watch'

done = ->
	console.log 'Done!'

task 'lint', 'Description', ->
	lint done

task 'all', 'Description', ->
	clean -> compile_compiler -> compile_smith -> run_smith done

task 'compile-compiler', 'Description', ->
	compile_compiler done

task 'compile-smith', 'Description', ->
	compile_compiler -> compile_smith done

task 'compile-and-run-smith', 'Description', ->
	compile_compiler -> compile_smith -> run_smith done

task 'just-run-smith', 'Description', ->
	run_smith done

task 'watch', ->
	watch done

