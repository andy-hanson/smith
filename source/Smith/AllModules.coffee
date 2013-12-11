io = require './io'

module.exports = class AllModules
	constructor: (@baseDir) ->
		type @baseDir, String
		# Maps dir name to Modules
		@moduleses = {}

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
				path

		@moduleses[dir] = modules

	###
	accessFile relative to @baseDor
	###
	get: (name, accessFile) ->
		type name, String
		type accessFile, String

		accessDir =
			io.dirOf accessFile

		if (name.startsWith './') or name.startsWith '../'
			name
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
