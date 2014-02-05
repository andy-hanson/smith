{ type } =  require '../help/✔'
Expression = require './Expression'

###
Simply wraps its content.
Useful during parsing to distinguish `(array) 3` from `array 3`.
###
module.exports = class Parend extends Expression
	# Simply takes the content to wrap.
	constructor: (@content) ->
		type @content, Expression
		{ @pos } = @content

	# @noDoc
	compile: (context) ->
		@content.compile context