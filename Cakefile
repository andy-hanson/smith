{ exec } = require 'child_process'

execHandle = (after) ->
	(err, stdout, stderr) ->
		out = stdout + stderr
		if out != ''
			console.log out
		throw err if err?
		after()

run = (command) ->
	(after) ->
		exec command, execHandle after

clean =
	run 'rm -rf js js-std'

lint =
	run 'coffeelint -f source/lintConfig.json source/*.coffee source/*/*.coffee'

compile_compiler =
	run 'coffee --compile --bare --map --output compiler-js source/Smith'

compile_main =
	# compile_compiler
	run 'bin/smith --just Main.smith --is-std'

compile_smith =
	# compile_compiler
	run 'bin/smith --quiet'

run_smith =
	# compile_smith
	run 'node js/run.js'

test =
	'node compiler-js/test.js'

watch =
	# compile_compiler
	'bin/smith --in source --out js-smith --watch'

done = ->
	null

task 'lint', 'Description', ->
	lint done

task 'clean', 'Description', ->
	clean done

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

