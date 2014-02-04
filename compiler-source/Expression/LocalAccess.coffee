{ type } =  require '../help/✔'
mangle = require '../help/mangle'
Pos = require '../compile-help/Pos'
Expression = require './Expression'
Local = require './Local'

module.exports = class LocalAccess extends Expression
	constructor: (@pos, @local) ->
		type @pos, Pos
		type @local, Local
		@local.isUsed()

	toString: ->
		@local.toString()

	compile: ->
		m = mangle @local.name
		if @local.lazy
			"#{m}()"
		else
			m