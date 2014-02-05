Options = require './run/Options'
compileDirectory = require './compile/directory'

###
Runs the main Smith program, using options from the command line.
For programmable compiles, see `compile/directory`.
###
main = ->
	if (options = Options.fromCommandLine())?
		compileDirectory options

module.exports =
	compileDirectory: compileDirectory
	compileSingle: require './compile/single'
	lex: require './lex'
	main: main
	Options: Options
	parse: require './parse'

