io = require './io'
fs = require 'fs'

module.exports = class AllModules
	constructor: (@baseDir) ->
		type @baseDir, String
		# Maps dir name to Modules
		@moduleses = {}

	###
	dir - directory of the modules file
	text - its contents
	###
	parse: (dir, text) ->
		type dir, String
		type text, String

		modules =
			{}

		parts =
			text.split '\n'

		for part, index in parts
			if part == '' or part.startsWith '#'
				continue
			split =
				part.split ' '
			check split.length == 2, ->
				"Unexpected module def at line #{index}: #{part}"
			[ name, path ] =
				split
			modules[name] =
				@findModule dir, path

		@moduleses[dir] = modules


	findModule: (dir, name) ->
		if name.startsWith './'
			name = io.join dir, name.withoutStart './'
		else if name.startsWith '../'
			name = io.join dir, io.dirOf name.withoutStart '../'

		full = io.join @baseDir, name
		if fs.existsSync full
			check (io.statKindSync full) == 'directory'
			name = io.join name, 'index'

		extensions =
			[ '.smith', '.coffee', '.js', '/index.smith', '/index.coffee', '/index.js' ]
		mayBeModules =
			extensions.map (extension) =>
				"#{name}#{extension}"

		for mayBeModule in mayBeModules
			if fs.existsSync io.join @baseDir, mayBeModule
				return name

		fail "There is no module #{name}; tried #{mayBeModules}"

	###
	name - What follows 'use'
	accessFile: file accessing it
	###
	get: (name, accessFile) ->
		type name, String
		type accessFile, String

		accessDir =
			io.dirOf accessFile

		if (name.startsWith './') or name.startsWith '../'
			@findModule accessDir, name
		else
			loop
				# TODO: hasownproperty
				if @moduleses[accessDir]?[name]?
					return @moduleses[accessDir]?[name]
				else
					if accessDir == ''
						# Search is over
						throw new Error "Could not find module of name #{name}"
					else
						accessDir = io.dirOf accessDir

	@load = (dir) ->
		type dir, String

		allModules =
			new AllModules dir

		io.readFilesNamedSync dir, 'modules', allModules.bound 'parse'

		allModules
