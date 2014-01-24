AllModules = require './AllModules'

module.exports = class Options
	constructor: (@_checks, @_meta, @_printModuleDefines, inDir) ->
		type @_checks, Boolean
		type @_meta, Boolean
		type @_printModuleDefines, Boolean

		@_allModules =
			AllModules.load inDir

		type @_allModules, AllModules

	checks: -> @_checks
	meta: -> @_meta
	printModuleDefines: -> @_printModuleDefines
	allModules: -> @_allModules