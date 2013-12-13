io = require './io'
fs = require 'fs'
path = require 'path'
Pos = require './Pos'
{ cCheck } = require './CompileError'
StringMap = require './StringMap'

module.exports = class AllModules
	constructor: (@baseDir) ->
		type @baseDir, String
		# Maps dir name to Modules
		@moduleses = new StringMap

	###
	dir - directory of the modules file
	text - its contents
	###
	parse: (dir, text) ->
		type dir, String
		type text, String

		try
			modules =
				new StringMap

			parts =
				text.split '\n'

			for part, index in parts
				if part == '' or part.startsWith '#'
					continue
				split =
					part.split ' '
				check split.length == 2, ->
					"Unexpected module def at line #{index}: #{part}"
				[ name, modulePath ] =
					split
				modules.add name, @findModule dir, modulePath

			@moduleses.add dir, modules

		catch error
			error.message =
				"In module file #{dir}/modules: #{error.message}"
			throw error


	findModule: (dir, name) ->
		if name.startsWith './'
			name = path.join dir, name.withoutStart './'
		else if name.startsWith '../'
			name = path.join dir, path.dirname name.withoutStart '../'

		full = path.join @baseDir, name
		if fs.existsSync full
			check (io.statKindSync full) == 'directory'
			name = path.join name, 'index'

		extensions =
			[ '.smith', '.coffee', '.js', '/index.smith', '/index.coffee', '/index.js' ]
		mayBeModules =
			extensions.map (extension) ->
				"#{name}#{extension}"

		for mayBeModule in mayBeModules
			if fs.existsSync path.join @baseDir, mayBeModule
				return name

		fail "There is no module #{name}; tried #{mayBeModules}"

	###
	name: What follows 'use'
	accessFile: file accessing it (relative to top)
	###
	get: (name, pos, accessFile) ->
		type name, String
		type pos, Pos
		type accessFile, String

		accessDir =
			path.dirname accessFile


		relToTop = do =>
			if (name.startsWith './') or name.startsWith '../'
				@findModule accessDir, name
			else
				lookupDir =
					accessDir
				loop
					# TODO: hasownproperty
					maybe =
						(@moduleses.maybeGet lookupDir)?.maybeGet name
					if maybe?
						return maybe
					else
						cCheck (not ['', '.'].contains lookupDir), pos, ->
							# Search is over
							"Could not find module #{name}"

						lookupDir = path.dirname lookupDir

		full =
			path.join @baseDir, relToTop

		fullAccess =
			path.join @baseDir, accessDir

		'./' + path.relative fullAccess, full


	@load = (dir) ->
		type dir, String

		allModules =
			new AllModules dir

		io.readFilesNamedSync dir, 'modules', allModules.bound 'parse'

		allModules
