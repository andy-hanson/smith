require './helpers'
#[ './helpers', './parse', './lex', './compile', 'fs', 'optimist']
io = require './io'
fs = require 'fs'
optimist = require 'optimist'
smithCompile = require './compile'
coffee = require 'coffee-script'
watch = require 'watch'

###
compileAndWrite = (inFile, outFile) ->
	#Compile a single file to a single output.
	console.log "Compiling #{inFile} to #{outFile}"

	source =
		fs.readFileSync inFile, 'utf8'
	compiled =
		smithCompile source, inFile, outFile

	fs.writeFileSync \
		outFile,
		compiled.code
	fs.writeFileSync \
		"#{outFile}.map",
		compiled.map
###

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

		switch ext
			when 'smith'
				out =
					"#{name}.js"
				{ code, map } =
					smithCompile text, inFile, out

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
				throw ext

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
		#Also copy 'prelude' there.
		#io.copyFlat 'prelude', outDir

		filter = @compilable.bind @
		io.processDirectorySync @inDir, @outDir, filter, @compile.bind @


	watch: ->
		toShortName = (inName) =>
			inName.withoutStart "#{@inDir}/"
		toOutName = (inName) =>
			"#{outDir}/#{toShortName inName}"

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
			monitor.on 'removed', (inFile) ->
				@log "#{inFile} was deleted."
				for outShort in outNames (toShortName inFile)
					outFile = "#{outDir}/#{outShort}"
					@log "Removing #{outFile}"
					fs.unlink outFile, (err) ->
						throw err if err?

	compileAndWrite: (inFile, text) ->
		(@compile inFile, text).forEach (compiled) =>
			[ shortOut, text ] = compiled
			outFile = "#{@outDir}/#{shortOut}"
			fs.writeFile outFile, text, (err) =>
				throw err if err?
				@log "Wrote to #{outFile}"

	main: ->
		#if @file?
		#	@compileAndWrite @file, (fs.readFileSync @file, 'utf8'), 'test'
		#else
		@compileAll()
		if @watch
			@log "Watching #{argv.in}..."
			@watch()


main = ->
	argv =
		optimist.options
			i:
				alias: 'in'
				describe: 'ay ay ay!'
			o:
				alias: 'out'
				describe: 'waaa'
			w:
				alias: 'watch'
				describe: 'hohoho'
				default: no
			q:
				alias: 'quiet'
				describe:' yoyoyo'
				default: no
			j:
				alias: 'just'
				describe: 'rururu'
				default: null
		.argv

	unless argv.help
		unless argv._.isEmpty()
			throw new Error "Unexpected #{argv._}"

		(new Smith argv).main()

test = ->
	(require './lexSpec')()

	#console.log argv
	#console.log commandline.in
	#(require './compile').test()

module.exports =
	parse: require './parse'
	lex: require './lex'
	compile: smithCompile
	#compileDir: compileDir
	main: main
	test: test


