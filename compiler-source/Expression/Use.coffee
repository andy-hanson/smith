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
	constructor: (use, fileName, allModules) ->
		type use, T.Use, fileName, String, allModules, AllModules
		{ @pos, @kind } = use
		name =
			new T.Name @pos, use.shortName(), 'x'
		@local =
			new Local name, null, use.lazy()
		@fullName =
			allModules.get use.used, @pos, fileName

	toString: ->
		"<#{@kind} #{@fullName}>"

	compile: (context) ->
		"require('#{@fullName}')"
		#(Literal.JS @pos, "require('#{@fullName}')").compile context

	# used in type-level eg
	@typeLocal = (typeName, fileName, allModules) ->
		x = new T.Use Pos.start, typeName, 'use!'
		new Use x, fileName, allModules
