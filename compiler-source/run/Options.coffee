nopt = require 'nopt'
AllModules = require '../compile/AllModules'
{ type } = require '../help/✔'

module.exports = class Options
	constructor: (opts) ->
		@_checks = opts.checks ? yes
		@_in = opts.in ? 'source'
		@_out = opts.out ? 'js'
		@_meta = opts.meta ? yes
		@_printModuleDefines = opts['print-module-defines'] ? no
		@_verbose = opts.verbose ? no
		@_watch = opts.watch ? no
		@_nazi = opts.nazi ? yes
		@_just = opts.just

		@_allModules =
			AllModules.load @in()

	[	'checks', 'in', 'out', 'meta',
		'printModuleDefines', 'verbose',
		'watch', 'nazi', 'just', 'allModules' ].forEach (x) =>
		@prototype[x] = ->
			@["_#{x}"]

	@fromCommandLine = ->
		opts = nopt
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

		if opts.help
			info = require './info'
			console.log """
			Smith compiler version #{info.version}.
			Use --no-X to turn of option X.
			Options:
			--in: Input directory (default 'source').
			--out: Ouput directory (default 'js').
			--checks: Turns on in, out, and type checks.
				(Does not affect ✔ not in a in or out block).
			--help: Print this.
			--meta: Include meta with functions (default yes).
			--print-module-defines: Include statements that print when a module is defined. (Debug)
			--verbose: Print when compiling files.
			--watch: Wait and compile again whenever files are changed.
			--nazi: Suppress unconventional syntax (default yes).
			--just: Only compile one file.
			"""

		new Options opts



	###
	opts.checks ?= yes
	opts.in ?= 'source'
	opts.out ?= 'js'
	opts.meta ?= yes
	opts['print-module-defines'] ?= no
	opts.verbose ?= no
	opts.watch ?= no
	opts.nazi ?= yes

	constructor: (@_checks, @_meta, @_printModuleDefines, @_nazi, inDir) ->
		type @_checks, Boolean,
			@_meta, Boolean,
			@_printModuleDefines, Boolean,
			@_nazi, Boolean,
			inDir, String

		@_allModules =
			AllModules.load inDir

		type @_allModules, AllModules

	checks: -> @_checks
	meta: -> @_meta
	printModuleDefines: -> @_printModuleDefines
	allModules: -> @_allModules
	nazi: -> @_nazi
	###