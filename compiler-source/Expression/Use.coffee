{ type } =  require '../help/✔'
AllModules = require '../compile/AllModules'
Expression = require './Expression'
Local = require './Local'
T = require '../Token'
Pos = require '../compile-help/Pos'

###
Represents requiring something.
Does NOT represent defining the local.
###
module.exports = class Use extends Expression
	###
	@param use [T.Use]
	@param fileName [String]
	@param allModules [AllModules]
	###
	constructor: (use, fileName, allModules) ->
		type use, T.Use, fileName, String, allModules, AllModules
		{ @pos, @kind } = use
		name =
			new T.Name @pos, use.shortName(), 'x'
		@local =
			new Local name, null, use.lazy()
		@fullName =
			allModules.get use.used, @pos, fileName

	# @noDoc
	compile: (context) ->
		"require('#{@fullName}')"

	###
	Type-level `eg` must `use` the type.
	###
	@typeLocal = (typeName, fileName, allModules) ->
		x = new T.Use Pos.start(), typeName, 'use!'
		new Use x, fileName, allModules
