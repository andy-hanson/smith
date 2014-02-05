{ type } = require '../help/✔'
T = require '../Token'
Pos = require '../compile-help/Pos'
Expression = require './Expression'

###
Expression whose meaning depends on nothing but its form.
Heavy lifting is handled by `Token.Literal` types.
###
module.exports = class Literal extends Expression
	###
	@param literal [T.Literal]
	  Token is passed through plainly.
	###
	constructor: (@literal) ->
		type @literal, T.Literal
		{ @pos } = @literal

	# @noDoc
	compile: (context) ->
		@literal.toJS context

	###
	Shortcut for JavaScript literal. Essentially wraps text with a Pos.
	###
	@JS: (pos, text) ->
		type pos, Pos, text, String
		new Literal new T.JavascriptLiteral pos, text, 'special'

	###
	Shortcut for String literal.
	###
	@string: (pos, text) ->
		type pos, Pos, text, String
		new Literal new T.StringLiteral pos, text
