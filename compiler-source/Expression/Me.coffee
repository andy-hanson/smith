{ type } =  require '../help/✔'
Pos = require '../compile-help/Pos'
Expression = require './Expression'

###
Looks like `me`.
Refers to the current object.
###
module.exports = class Me extends Expression
	# Only needs pos.
	constructor: (@pos) ->
		type @pos, Pos

	# @noDoc
	compile: ->
		'this'
