{ type } =  require '../help/✔'
T = require '../Token'
Expression = require './Expression'
Me = require './Me'

###
Looks like `a@property`.
Gets a property of an object, JavaScript style.
###
module.exports = class AccessProperty extends Expression
	###
	`subject`'s property of name `propertyName` is accessed.
	###
	constructor: (@subject, @propertyName) ->
		type @subject, Expression, @propertyName, T.Name
		{ @pos } = @propertyName

	# @noDoc
	compile: (context) ->
		[ (@subject.toNode context), "['", @propertyName.text, "']" ]

	###
	Property access on `me`.
	###
	@me: (pos, name) ->
		new AccessProperty (new Me pos), name