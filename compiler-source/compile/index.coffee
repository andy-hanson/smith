fs = require 'fs'
path = require 'path'
watch = require 'watch'
{ check, type } =  require '../help/✔'
{ endsWith, withoutEnd } = require '../help/str'
{ isEmpty } = require '../help/list'
io = require '../help/io'
compileCoffeeScript = (require 'coffee-script').compile
Options = require '../run/Options'
keywords = require '../compile-help/keywords'
compileSingle = require './single'

class CompileDir
	constructor: (@options) ->
		type @options, Options

	log: (text) ->
		if @options.verbose()
			console.log text

	###
	Returns a list of [name, text] pairs to write.
	###
	compile: (inFile, text) ->
		type inFile, String, text, String

		check @compilable inFile

		[ name, ext ] =
			io.extensionSplit inFile

		try
			switch ext
				when 'smith'
					@log "Compiling #{inFile}"
					out =
						"#{name}.js"
					{ code, map } =
						compileSingle text, inFile, out, @options

					[	[ out, code ],
						[ "#{out}.map", map.toString() ] ]

				when 'coffee'
					@log "Compiling #{inFile}"
					{ js, v3SourceMap } =
						compileCoffeeScript text,
							filename: inFile
							sourceMap: yes

					[	[ "#{name}.js", js ],
						[ "#{name}.js.map", v3SourceMap ] ]

				else
					[ [ inFile, text ] ]

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
				else
					[ inFile, inFile ]

	compilable: (inName) ->
		if @options.just()?
			inName == @options.just()
		else
			not isEmpty @outNames inName

	compileAll: ->
		io.processDirectorySync @options.in(), @options.out(),
			((file) => @compilable file), (file, text) => @compile file, text

		@writeAll()

	writeAll: ->
		all = []
		io.recurseDirectoryFilesSync @options.in(), (-> yes), (inFile) =>
			#Array.prototype.push.apply all, @outNames inFile
			(@outNames inFile).forEach (name) ->
				if endsWith name, 'js'
					all.push name

		useAll =
			all.map (module) ->
				"require('./#{withoutEnd module, '.js'}');"
			.join '\n'
		fs.writeFileSync (path.join @options.out(), "#{keywords.useAll}.js"), useAll


	watch: ->
		toShortName = (inName) =>
			io.relativeName @options.in(), inName
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

		watch.createMonitor @options.in(), options, (monitor) =>
			monitor.on 'created', compileAndWrite
			monitor.on 'changed', compileAndWrite
			monitor.on 'removed', (inFile) =>
				@log "#{inFile} was deleted."
				for shortOut in outNames (toShortName inFile)
					outFile = path.join @options.out(), shortOut
					@log "Removing #{outFile}"
					fs.unlink outFile, (err) ->
						throw err if err?

	compileAndWrite: (inFile, text) ->
		(@compile inFile, text).forEach (compiled) =>
			[ shortOut, text ] = compiled
			outFile = path.join @options.out(), shortOut
			fs.writeFile outFile, text, (err) =>
				throw err if err?
				@log "Wrote to #{outFile}"

	main: ->
		@compileAll()

		if @options.watch()
			@log "Watching #{@options.in()}..."
			@watch()

module.exports = (options) ->
	type options, Options
	(new CompileDir options).main()



