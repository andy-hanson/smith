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
		{ @watch, @quiet } = argv
		type @inDir, String
		type @outDir, String
		type @watch, Boolean
		type @quiet, Boolean

	log: (text) ->
		unless @quiet
			console.log "QUIET: #{@quiet}"
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

				[ [ out, code ], [ "#{out}.map", map.toString() ] ]

			when 'js'
				[ [ inFile, text ] ]

			when 'coffee'
				[ [ "#{name}.js", coffee.compile text ] ]

			else
				throw ext

	outNames: (inFile) ->
		[ name, ext ] =
			io.extensionSplit inFile

		switch ext
			when 'smith'
				[ "#{name}.js", "#{name}.js.map" ]
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
		not (@outNames inName).isEmpty()

	compileAll: ->
		#Also copy 'prelude' there.
		#io.copyFlat 'prelude', outDir

		filter = ((x) => @compilable x)
		io.processDirectorySync @inDir, @outDir, filter, ((file, text) => @compile file, text)


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
						compile (toShortName inFile), text, log

					compiles.forEach (compiled) =>
						[ shortOut, text ] = compiled
						outFile = "#{@outDir}/#{shortOut}"
						fs.writeFile outFile, text, (err) =>
							throw err if err?
							@log "Wrote to #{outFile}"

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

	main: ->
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
				default: '.'
			o:
				alias: 'out'
				describe: 'waaa'
				default: './smith-js'
			w:
				alias: 'watch'
				describe: 'hohoho'
				default: no
			q:
				alias: 'quiet'
				describe:' yoyoyo'
				default: no
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


