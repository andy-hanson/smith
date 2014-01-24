require './helpers'
#[ './helpers', './parse', './lex', './compile', 'fs', 'optimist']
io = require './io'
fs = require 'fs'
path = require 'path'
nopt = require 'nopt'
smithCompile = require './compile'
coffee = require 'coffee-script'
watch = require 'watch'
Options = require './Options'

class Smith
	constructor: (opts) ->
		@inDir = opts.in
		@outDir = opts.out
		{ @watch, @quiet, @just } = opts
		@options = new Options opts.checks, opts.meta, opts['print-module-defines'], @inDir
		type @inDir, String
		type @outDir, String
		type @watch, Boolean
		type @quiet, Boolean
		type @just, String if @just?

	log: (text) ->
		unless @quiet
			console.log text

	###
	Returns a list of [name, text] pairs to write.
	###
	compile: (inFile, text) ->
		type inFile, String
		type text, String

		check @compilable inFile

		@log "Compiling #{inFile}"

		[ name, ext ] =
			io.extensionSplit inFile

		try
			switch ext
				when 'smith'
					out =
						"#{name}.js"
					{ code, map } =
						smithCompile text, inFile, out, @options

					[	[ out, code ],
						[ "#{out}.map", map.toString() ] ]
						#[ inFile, text ] ]

				when 'js'
					[ [ inFile, text ] ]

				when 'coffee'
					{ js, v3SourceMap } =
						coffee.compile text,
							filename: inFile
							sourceMap: yes

					[	[ "#{name}.js", js ],
						[ "#{name}.js.map", v3SourceMap ] ]

				else
					fail()

		catch error
			error.message =
				"Error compiling #{inFile}:#{error.message}"
			throw error

	outNames: (inFile) ->
		if (path.basename inFile) == 'modules'
			[ ]
		else
			[ name, ext ] =
				io.extensionSplit inFile

			switch ext
				when 'smith'
					[ "#{name}.js", "#{name}.js.map", "#{name}.smith" ]
				when 'js'
					[ name ]
				when 'coffee'
					[ "#{name}.js" ]
				when '.kate-swp'
					[ ]
				else
					@log "Ignoring #{inFile}"
					[ ]

	compilable: (inName) ->
		if @just?
			inName == @just
		else
			not (@outNames inName).isEmpty()

	compileAll: ->
		io.processDirectorySync @inDir, @outDir,
			(@bound 'compilable'), @bound 'compile'

		@writeAll()

	writeAll: ->
		all = []
		io.recurseDirectoryFilesSync @inDir, (@bound 'compilable'), (inFile) =>
			#Array.prototype.push.apply all, @outNames inFile
			x = inFile.withoutEnd path.extname inFile
			all.push "#{x}.js"

		requires = all.map (module) ->
			"require('./#{module}');"
		out = requires.join '\n'
		fs.writeFileSync (path.join @outDir, 'require-all.js'), out


	watch: ->
		toShortName = (inName) =>
			io.relativeName @inDir, inName
		toOutName = (inName) ->
			path.join outDir, toShortName inName

		compileAndWrite = (inFile) =>
			type inFile, String

			if compilable inFile
				fs.readFile inFile, 'utf8', (err, text) =>
					throw err if err?
					compiles =
						compile (toShortName inFile), text

					@compileAndWrite (toShortName inFile), text

		options =
			interval: 1000
			ignoreDotFiles: yes
			#filter: compilable

		watch.createMonitor @inDir, options, (monitor) =>
			monitor.on 'created', compileAndWrite
			monitor.on 'changed', compileAndWrite
			monitor.on 'removed', (inFile) =>
				@log "#{inFile} was deleted."
				for shortOut in outNames (toShortName inFile)
					outFile = path.join @outDir, shortOut
					@log "Removing #{outFile}"
					fs.unlink outFile, (err) ->
						throw err if err?

	compileAndWrite: (inFile, text) ->
		(@compile inFile, text).forEach (compiled) =>
			[ shortOut, text ] = compiled
			outFile = path.join @outDir, shortOut
			fs.writeFile outFile, text, (err) =>
				throw err if err?
				@log "Wrote to #{outFile}"

	main: ->
		@compileAll()

		if @watch
			@log "Watching #{argv.in}..."
			@watch()


main = ->
	opts = nopt
		'checks': Boolean
		'in': String
		out: String
		'help': Boolean
		'meta': Boolean
		'just': String
		'print-module-defines': Boolean
		'quiet': Boolean
		'watch': Boolean

	opts.checks ?= yes
	opts.in ?= 'source'
	opts.out ?= 'js'
	opts.meta ?= yes
	opts['print-module-defines'] ?= no
	opts.quiet ?= yes
	opts.watch ?= no

	if opts.help?
		console.log "Help yourself!"
	else
		(new Smith opts).main()

module.exports =
	parse: require './parse'
	lex: require './lex'
	compile: smithCompile
	main: main


