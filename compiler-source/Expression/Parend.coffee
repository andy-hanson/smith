{ type } =  require '../help/✔'
Expression = require './Expression'

module.exports = class Parend extends Expression
	constructor: (@content) ->
		type @content, Expression
		{ @pos } = @content

	toString: ->
		"(#{@content})"

	compile: (context) ->
		@content.compile context
