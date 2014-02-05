{ toStringLiteral } = require '../compile-help/JavaScript-syntax'
Pos = require '../compile-help/Pos'
{ abstract, type } = require '../help/✔'
{ indented } = require '../help/str'
Token = require './Token'

###
A literal means what it looks like. The parser just passes them through.
@abstract
###
class @Literal extends Token
	###
	JavaScript representation of this Literal.
	@abstract
	###
	toJS: ->
		abstract()

###
Looks like `1.23`.
A number.
###
class @NumberLiteral extends @Literal
	# Currently `value` is never converted to a number.
	constructor: (@pos, @value) ->
		type @value, String

	# @noDoc
	show: ->
		@value.toString()

	# @noDoc
	toJS: ->
		"(#{@value})"

###
Looks like `javascript`.
Embedded JavaScript.
###
class @JavascriptLiteral extends @Literal
	###
	@param kind [String]
	  indented: This is indented JS, pass it through as a block.
	  plain: On one line, wrap it in parentheses.
	  special: Used by Smith compiler, pass it through plainly.
	###
	constructor: (@pos, @text, @kind) ->
		type @pos, Pos, @text, String, @kind, String

	# @noDoc
	show: ->
		"`#{@text}`"

	# @noDoc
	toJS: (context) ->
		switch @kind
			when 'indented'
				indented @text, context.indent()
			when 'plain'
				"(#{@text})"
			when 'special'
				@text
			else
				fail()

###
Looks like 'string or "string".
The text looks like its value (except for escape sequences).
###
class @StringLiteral extends @Literal
	# @param text [String] Unescaped contents of the string.
	constructor: (@pos, @text) ->
		type @pos, Pos, @text, String

	# @noDoc
	show: ->
		@toJS()

	# @noDoc
	toJS: ->
		toStringLiteral @text
