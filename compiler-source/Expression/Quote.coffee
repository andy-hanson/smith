{ type } =  require '../help/✔'
Pos = require '../compile-help/Pos'
Expression = require './Expression'

module.exports = class Quote extends Expression
	constructor: (@pos, @parts) ->
		type @pos, Pos
		type @parts, Array

	toString: ->
		'"' + @parts.join '|' + '"'

	compile: (context) ->
		nodes =
			@parts.map (part) ->
				part.toNode context

		[ '_s(', (nodes.join ', '), ')' ]
