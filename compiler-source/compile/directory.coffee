fs = require 'fs'
path = require 'path'
watch = require 'watch'
coffeeScript = require 'coffee-script'
{ check, type } =  require '../help/✔'
{ endsWith, withoutEnd } = require '../help/str'
{ isEmpty } = require '../help/list'
io = require '../help/io'
Options = require '../run/Options'
keywords = require '../compile-help/keywords'
AllModules = require './AllModules'
compileSingle = require './single'

###
Responsible for compiling the whole directory.
@private
###
class CompileDir
	# Only member is `@options`.
	constructor: (@options) ->
		type @options, Options
		@allModules =
			AllModules.load @options.in()

	###
	If false, file `inName` is skipped over.
	###
	compilable: (inName) ->
		if @options.just()?
			inName == @options.just()
		else
			not isEmpty @outNames inName

	###
	Returns a list of [name, text] pairs to write.
	@param inFile [String] The input file (relative to `--in`)
	@param code [String] contents of inFile.
	@return [Array<(String, String)>] List of [fileName, code] to write to `--out`.
	###
	compile: (inFile, code) ->
		type inFile, String, code, String

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
						compileSingle code, inFile, out, @options, @allModules

					x = [ [ out, code ], [ "#{out}.map", map.toString() ] ]
					if @options.copySources()
						x.push [ inFile, code ]
					x

				when 'coffee'
					@log "Compiling #{inFile}"
					{ js, v3SourceMap } =
						coffeeScript.compile code,
							filename: inFile
							sourceMap: yes

					[	[ "#{name}.js", js ],
						[ "#{name}.js.map", v3SourceMap ] ]

				else
					[ [ inFile, code ] ]

		catch error
			error.message =
				"Error compiling #{inFile}:#{error.message}"
			throw error

	###
	Compile all files in `--in`.
	###
	compileAll: ->
		io.processDirectorySync @options.in(), @options.out(),
			((file) => @compilable file), (file, text) => @compile file, text

	# Ouput the text if `--verbose`
	log: (text) ->
		if @options.verbose()
			console.log text

	###
	Compile everything, and if `--watch`, keep watching.
	###
	main: ->
		@compileAll()
		@watch() if @options.watch()

	###
	Returns a list of the file names written to by `compile`.
	###
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


	###
	TODO: Poorly tested.
	###
	watch: ->
		@log "Watching #{@options.in()}..."

		compileAndWrite = (inFile) =>
			type inFile, String

			if compilable inFile
				fs.readFile inFile, 'utf8', (err, text) =>
					throw err if err?

					(@compile inFile, text).forEach (compiled) =>
						[ out, text ] = compiled
						outFile = path.join @options.out(), out
						fs.writeFile outFile, text, (err) =>
							throw err if err?
							@log "Wrote to #{outFile}"

		options =
			interval: 2000
			ignoreDotFiles: yes

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

###
Recursively compiles the directory.
@param options [Options] Project compilation options.
###
module.exports = compileDirectory = (options) ->

	type options, Options
	(new CompileDir options).main()
