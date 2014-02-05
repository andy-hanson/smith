{ fail, type } =  require '../help/✔'
Expression = require './Expression'

###
Looks like `...args` in `method a b ...args`.
Represents when many arguments are passed into a `Call` at once.
###
module.exports = class ManyArgs
	###
	Simply wraps the value.
	###
	constructor: (@value) ->
		type @value, Expression
		@pos = @value.pos
