{ type } =  require '../help/✔'
Pos = require '../compile-help/Pos'
Expression = require './Expression'
Local = require './Local'

###
Looks like `localName`.
Accesses a Local.
###
module.exports = class AccessLocal extends Expression
	# @param local [Local]
	constructor: (@pos, @local) ->
		type @pos, Pos, @local, Local
		@local.isUsed()

	# @noDoc
	compile: ->
		if @local.lazy
			[ @local.mangled(), '()' ]
		else
			@local.mangled()