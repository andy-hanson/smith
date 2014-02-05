{ type } =  require '../help/✔'
{ interleave } = require '../help/list'
Pos = require '../compile-help/Pos'
T = require '../Token'
Expression = require './Expression'

###
Looks like "blah {1.+ 1} blah"
Represents a quote, possibly with interpolations.
###
module.exports = class Quote extends Expression
	###
	@param parts [Array<Expression>]
	###
	constructor: (@pos, @parts) ->
		type @pos, Pos
		type @parts, Array

	# @noDoc
	compile: (context) ->
		if @parts.length == 1
			type @parts[0].literal, T.StringLiteral
			@parts[0].toNode context

		partNodes =
			@parts.map (part) ->
				part.toNode context

		[ '_s(', (interleave partNodes, ', '), ')' ]
