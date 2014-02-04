{ type } =  require '../help/✔'
T = require '../Token'
Expression = require './Expression'
Me = require './Me'

module.exports = class PropertyAccess extends Expression
	constructor: (@subject, @prop) ->
		type @subject, Expression, @prop, T.Name
		{ @pos } = @prop

	toString: ->
		"#{@subject},#{@prop.text}"

	compile: (context) ->
		[ (@subject.toNode context), "['", @prop.text, "']" ]

	@me = (pos, name) ->
		new PropertyAccess (new Me pos), name