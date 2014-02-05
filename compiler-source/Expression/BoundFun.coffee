{ type } =  require '../help/✔'
T = require '../Token'
Expression = require './Expression'
Me = require './Me'

###
Looks like `a.method_`.
A method bound to an object.
Basically, `a@method.bind a`.
###
module.exports = class BoundFun extends Expression
	###
	Binds `subject`'s method `name`.
	###
	constructor: (@subject, @name) ->
		type @subject, Expression, @name, T.Name
		{ @pos } = @name

	# @noDoc
	compile: (context) ->
		[ '_b(', (@subject.toNode context), ", '", @name.text, "')" ]

	###
	Looks like `method_`.
	A method bound to `me`.
	###
	@me: (name) ->
		new BoundFun (new Me name.pos), name

