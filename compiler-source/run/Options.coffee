nopt = require 'nopt'
AllModules = require '../compile/AllModules'
{ type } = require '../help/✔'
{ read } = require '../help/meta'

###
Stores compilation options.
Run `smith --help` to see all.
###
module.exports = class Options
	###
	Constructs options from an object.
	All members are  optional.
	@param options
	  Object containing options specified in `smith --help`.
	@example
	  Options
	  	'print-module-defines': yes
	  	nazi: yes
	###
	constructor: (options) ->
		@_in = options.in ? 'source'
		@_out = options.out ? 'js'
		@_checks = options.checks ? yes
		@_copySources = options['copy-sources'] ? no
		@_just = options.just
		@_meta = options.meta ? yes
		@_nazi = options.nazi ? yes
		@_printModuleDefines = options['print-module-defines'] ? no
		@_verbose = options.verbose ? no
		@_watch = options.watch ? no

	read @, 'allModules', 'in', 'out', 'checks',
		'copySources', 'just', 'meta', 'nazi',
		'printModuleDefines', 'verbose', 'watch'

	###
	Gets Options from this processe's command line.
	###
	@fromCommandLine: ->
		options = nopt
			checks: Boolean
			'in': String
			out: String
			help: Boolean
			meta: Boolean
			just: String
			'print-module-defines': Boolean
			verbose: Boolean
			watch: Boolean
			nazi: Boolean

		if options.help
			info = require './info'
			console.log """
			Smith compiler version #{info.version}.
			Use --no-X to turn of option X.
			Options:
			--in: Input directory (default 'source').
			--out: Ouput directory (default 'js').
			--checks: Turns on in, out, and type checks.
				(Does not affect ✔ not in a in or out block).
			--copy-sources: If so, copies .smith files to out directory.
			--help: Print this.
			--just: Only compile one file.
			--meta: Include meta with functions (default yes).
			--nazi: Suppress unconventional syntax (default yes).
			--print-module-defines: Output code prints when modules are defined.
			--verbose: Print when compiling files.
			--watch: Wait and compile again whenever files are changed.
			"""

		new Options options
