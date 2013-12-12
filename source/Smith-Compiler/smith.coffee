require './helpers'
#[ './helpers', './parse', './lex', './compile', 'fs', 'optimist']
io = require './io'
fs = require 'fs'
path = require 'path'
optimist = require 'optimist'
smithCompile = require './compile'
coffee = require 'coffee-script'
watch = require 'watch'
AllModules = require './AllModules'

class Smith
	constructor: (argv) ->
		@inDir = argv.in
		@outDir = argv.out
		{ @watch, @quiet, @just } = argv
		type @inDir, String
		type @outDir, String
		type @watch, Boolean
		type @quiet, Boolean
		type @just, String if @just

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
						smithCompile text, inFile, out, @allModules

					[	[ out, code ],
						[ "#{out}.map", map.toString() ],
						[ inFile, text ] ]

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
				"Error compiling #{inFile}: #{error.message}"
			throw error

	outNames: (inFile) ->
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
		filter =
			@bound 'compilable'
		io.processDirectorySync @inDir, @outDir, filter, @bound 'compile'


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
		@allModules =
			AllModules.load @inDir

		@compileAll()

		if @watch
			@log "Watching #{argv.in}..."
			@watch()


main = ->
	argv =
		optimist
		.usage('I am usage string')
		.options
			i:
				alias: 'in'
				describe: 'Source files top-level directory'
				default: 'source'
			o:
				alias: 'out'
				describe: 'Compiled output directory'
				default: 'js'
			w:
				alias: 'watch'
				describe: 'Wait to respond to changes in source directory'
				default: no
			q:
				alias: 'quiet'
				describe:' Disables logging'
				default: no
			j:
				alias: 'just'
				describe: 'Only compile this file'
				default: null
		.argv

	unless argv.help
		unless argv._.isEmpty()
			throw new Error "Unexpected #{argv._}"

		(new Smith argv).main()

module.exports =
	parse: require './parse'
	lex: require './lex'
	compile: smithCompile
	main: main


