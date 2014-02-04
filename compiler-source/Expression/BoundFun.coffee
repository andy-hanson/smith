{ type } =  require '../help/✔'
T = require '../Token'
Expression = require './Expression'
Me = require './Me'

###
func_
.func_
###
module.exports = class BoundFun extends Expression
	constructor: (@subject, @name) ->
		type @subject, Expression, @name, T.Name
		{ @pos } = @name

	compile: (context) ->
		[ '_b(', (@subject.toNode context), ", '", @name.text, "')" ]

	@me = (name) ->
		new BoundFun (new Me name.pos), name

