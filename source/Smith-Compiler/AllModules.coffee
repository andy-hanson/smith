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
				unexpected = ->
					"Unexpected module def at line #{index}: #{part}"
				force =
					split.length == 3
				if force
					check split[2] == 'FORCE', unexpected
				else
					check split.length == 2, unexpected
				[ name, modulePath ] =
					split
				fullName =
					if force
						modulePath
					else
						@findFullName dir, modulePath

				modules.add name, { fullName: fullName , force: force }

			@moduleses.add dir, modules

		catch error
			error.message =
				"In module file #{dir}/modules: #{error.message}"
			throw error

	###
	Find the module from its (relative) file name.
	Checks for .smith, .coffee, .js, or folder with index (.smith, .coffee, .js)

	dir - path relative to @baseDir
	name - module name

	Returns the usage name (with '.js' left implied)
	###
	findFullName: (dir, name, fromGet = no) ->
		if name.startsWith './'
			name = path.join dir, name.withoutStart './'
		else if name.startsWith '../'
			name = path.join dir, path.dirname name.withoutStart '../'
		# else name is relative to top

		full = path.join @baseDir, name
		if fs.existsSync full
			check (io.statKindSync full) == 'directory'
			name = path.join name, 'index'

		extensions =
			[ '.smith', '.coffee', '.js' ]
		mayBeModules =
			extensions.map (extension) ->
				"#{name}#{extension}"

		for mayBeModule in mayBeModules
			if fs.existsSync path.join @baseDir, mayBeModule
				return name

		message =
			if fromGet
				"Could not find module #{name} in modules listing or locally"
			else
				"There is no module at #{name}; tried #{mayBeModules}"

		fail message

	noForce: (fullName) ->
		fullName: fullName
		force: no

	###
	Get the module for a given name.

	name: What follows 'use'
	accessFile: file accessing it (relative to top)
	###
	get: (name, pos, accessFile) ->
		type name, String
		type pos, Pos
		type accessFile, String

		accessDir =
			path.dirname accessFile

		module = do =>
			if (name.startsWith './') or name.startsWith '../'
				@noForce @findFullName accessDir, name
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
						if ['', '.'].contains lookupDir
							# It wasn't in modules listing, see if it's relative
							return @noForce @findFullName accessDir, "./#{name}", yes
						else
							lookupDir = path.dirname lookupDir

		if module.force
			module.fullName
		else
			full =
				path.join @baseDir, module.fullName

			fullAccess =
				path.join @baseDir, accessDir

			"./#{path.relative fullAccess, full}"

	###
	Load the modules listings for a directory.
	###
	@load = (dir) ->
		type dir, String

		allModules =
			new AllModules dir

		io.readFilesNamedSync dir, 'modules', allModules.bound 'parse'

		allModules
