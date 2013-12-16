io = require './io'
fs = require 'fs'
path = require 'path'
Pos = require './Pos'
{ cCheck } = require './CompileError'
StringMap = require './StringMap'
T = require './Token'
E = require './Expression'

class Module
	constructor: (@fullName, @force) ->
		type @fullName, String
		type @force, Boolean

class Modules
	constructor: ->
		@modules = new StringMap
		@autos = []
		@autoBangs = []

	add: (name, fullName, force) ->
		@modules.add name, new Module fullName, force

	addAutos: (names, kind) ->
		switch kind
			when 'auto'
				@autos = @autos.concat names
			when 'auto!'
				@autoBangs = @autoBangs.concat names
			else
				fail()

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
				new Modules

			for part, index in text.split '\n'
				part = (part.split '#')[0]
				continue if part == ''
				split =
					part.split ' '
				unexpected = ->
					"Unexpected module def at line #{index}: #{part}"

				if ['auto', 'auto!'].contains split[0]
					modules.addAutos split.tail(), split[0]
				else
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

					modules.add name, fullName, force

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

	autoUses: (fileName) ->
		lookupDir = path.dirname fileName
		uses = []

		loop
			modules = @moduleses.maybeGet lookupDir
			if modules?
				au = (bang) => (auto) =>
					useT = new T.Use Pos.start, auto, (if bang then 'use!' else 'use')
					uses.push new E.Use useT, fileName, @

				modules.autos.forEach au no
				modules.autoBangs.forEach au yes

			if ['', '.'].contains lookupDir
				return uses
			else
				lookupDir = path.dirname lookupDir

	###
	_iterModules: (accessDir, getter, final) ->
		lookupDir =
			accessDir

		do => loop
			maybe =
				@moduleses.maybeGet lookupDir
			if maybe?
				got = getter maybe
				if got?
					got
			else
				if ['', '.'].contains lookupDir
					return final accessDir
				else
					lookupDir = path.dirname lookupdir
	###

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

		module =
			if (name.startsWith './') or name.startsWith '../'
				@noForce @findFullName accessDir, name
			else
				lookupDir =
					accessDir
				do => loop
					maybe =
						(@moduleses.maybeGet lookupDir)?.modules.maybeGet name
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
