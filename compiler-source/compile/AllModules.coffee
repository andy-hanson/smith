fs = require 'fs'
path = require 'path'
{ check, fail, type } = require '../help/✔'
io = require '../help/io'
{ tail } = require '../help/list'
StringMap = require '../help/StringMap'
Pos = require '../compile-help/Pos'
{ cCheck } = require '../compile-help/✔'
T = require '../Token'
keywords = require '../compile-help/keywords'

###
Represents how to access a single module.
`@force`: If so, the module is not a file in the source directory.
###
class Module
	###
	@param fullName [String] Full path to the module.
	@param force [Boolean] If so, module path is not checked.
	###
	constructor: (@fullName, @force) ->
		type @fullName, String, @force, Boolean
		Object.freeze @

###
The result of parsing a single `modules` file.
`@autos` and `@autoBangs` store what files in its directory automatically use.
###
class Modules
	# Starts empty.
	constructor: ->
		@modules = new StringMap
		@autos = [ ]
		@autoBangs = [ ]

	###
	Get a new module.
	###
	add: (name, fullName, force) ->
		type name, String, fullName, String, force, Boolean
		@modules.add name, new Module fullName, force

	###
	@param names [Array<String>] `use`s to be included automatically.
	@param kind [String] 'auto' or 'auto!'
	###
	addAutos: (names, kind) ->
		switch kind
			when 'auto'
				@autos = @autos.concat names
			when 'auto!'
				@autoBangs = @autoBangs.concat names
			else
				fail()

###
Handles every `modules` file.
###
module.exports = class AllModules
	###
	@param baseDir [String] Top-level source directory.
	###
	constructor: (@baseDir) ->
		type @baseDir, String
		# Maps dir names to their `modules` files.
		@moduleses = new StringMap

	###
	Gets the info of a single modules file.
	@param dirName [String] directory of the `modules` file.
	@param text [String] Contents of the file.
	###
	parse: (dirName, text) ->
		type dirName, String, text, String

		try
			modules =
				new Modules

			for part, index in text.split '\n'
				part = (part.split '\\')[0] # take out comments
				continue if part == '' # ignore empty lines

				split =
					part.split ' '

				unexpected = ->
					"Unexpected module def at line #{index}: #{part}"

				if split[0] in [ 'auto', 'auto!' ]
					modules.addAutos (tail split), split[0]
				else
					force =
						split.length == 3
					if force
						check split[2] == 'FORCE', unexpected
					else
						check split.length == 2, unexpected
					[ name, modulePath ] =
						split
					type name, String, modulePath, String
					fullName =
						if force
							modulePath
						else
							path.join dirName, @_findLocal dirName, modulePath
					type fullName, String
					modules.add name, fullName, force

			@moduleses.add dirName, modules

		catch error
			error.message =
				"In module file #{dirName}/modules: #{error.message}"
			throw error

	###
	Get a module relative to `dirName`.
	@private
	###
	_findLocal: (dirName, name) ->
		(@_maybeFindLocal dirName, name) ? fail "Can not find #{dirName}/#{name}"

	###
	Get a module name relative to `dirName`, or `null`.
	@param dirName [String] Path relative to `@baseDir`.
	@param name [String] Module name.
	@private
	###
	_maybeFindLocal: (dirName, name) ->
		type dirName, String
		type name, String

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
			full = path.join @baseDir, dirName, mayBeModule
			if fs.existsSync full
				return name

		return null


	###
	List of every automatic use for a given file.
	@return [Array<E.Use>]
	###
	autoUses: (fileName) ->
		lookupDir = path.dirname fileName
		uses = [ ]

		loop
			modules = @moduleses.maybeGet lookupDir
			if modules?
				au = (bang) => (auto) =>
					useT = new T.Use Pos.start(), auto, (if bang then 'use!' else 'use')
					E = require '../Expression'
					uses.push new E.Use useT, fileName, @

				type au, Function
				modules.autos.forEach au no
				modules.autoBangs.forEach au yes

			if lookupDir in [ '', '.' ]
				return uses
			else
				lookupDir = path.dirname lookupDir

	###
	Get the module for a given name.
	Returns the module's path relative to the access directory.

	@param name [String] What follows `use`.
	@param pos [Pos] Position of use.
	@param accessFile [String File accessing it (relative to top).
	###
	get: (name, pos, accessFile) ->
		type name, String
		type pos, Pos
		type accessFile, String

		accessDir =
			path.dirname accessFile

		maybeLocal =
			@_maybeFindLocal accessDir, name

		if maybeLocal?
			"./#{maybeLocal}"
		else
			lookupDir =
				accessDir
			module = do =>
				loop
					maybe =
						(@moduleses.maybeGet lookupDir)?.modules.maybeGet name
					if maybe?
						return maybe
					else
						if lookupDir in [ '', '.' ]
							# It wasn't in modules listing, see if it's relative
							#return @_noForce @findFullName accessDir, "./#{name}", yes
							fail "Could not find module #{name} in modules listing or locally"
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
	Loads the modules listings for a directory.
	###
	@load: (dir) ->
		type dir, String

		allModules =
			new AllModules dir

		io.readFilesNamedSync dir, 'modules', (modulesFile, text) ->
			allModules.parse modulesFile, text

		allModules
