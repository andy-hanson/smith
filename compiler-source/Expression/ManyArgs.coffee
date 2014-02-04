{ fail, type } =  require '../help/✔'
Expression = require './Expression'

module.exports = class ManyArgs extends Expression
	constructor: (@value) ->
		type @value, Expression
		@pos = @value.pos

	compile: ->
		fail "Should not be compiling ManyArgs"

	toString: ->
		"...#{@value}"
