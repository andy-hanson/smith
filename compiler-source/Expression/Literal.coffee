{ type } = require '../help/✔'
T = require '../Token'
Pos = require '../compile-help/Pos'
Expression = require './Expression'

module.exports = class Literal extends Expression
	constructor: (@literal) ->
		type @literal, T.Literal
		{ @pos } = @literal

	toString: ->
		"<#{@literal}>"

	compile: (context) ->
		@literal.toJS context

	@JS = (pos, text) ->
		type pos, Pos, text, String
		new Literal new T.JavascriptLiteral pos, text, 'special'
