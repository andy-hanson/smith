Options = require './run/Options'
compileDir = require './compile'

main = ->
	if (options = Options.fromCommandLine())?
		compileDir options

module.exports =
	lex: require './lex'
	parse: require './parse'
	compileSingle: require './compile/single'
	compileDir: compileDir
	main: main

