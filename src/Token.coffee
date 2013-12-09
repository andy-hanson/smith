Pos = require './Pos'

class Token
	toString: ->
		"#{@show()}@#{@pos}"

	inspect: ->
		@toString()

class Name extends Token
	@kinds = ['x', '_x', 'x_', '.x', '.x_', ':x']

	constructor: (@pos, @text, @kind) ->
		type @pos, Pos
		type @text, String

		check (Name.kinds.contains @kind), =>
			"Name kind #{@kind} not in #{Name.kinds}"

	show: ->
		"<#{@type} #{@text}>"


class Group extends Token
	constructor: (openPos, closePos, open, close, @body) ->
		type openPos, Pos
		type closePos, Pos
		type open, String
		type close, String
		type body, Array

		expectedClose =
			Group.match[open]

		if close != expectedClose
			throw new Error "#{open}@#{openPos} no match #{close}@#{closePos}"

		@kind =
			if open == '->'
				'{'
			else
				open
		@pos = openPos

	show: ->
		"#{@kind}#{@body}#{Group.match[@type]}"

	@match =
		'(': ')'
		'[': ']'
		'{': '}'
		'->': '<-'
		'"': '"'
		'|': '|'

class Literal extends Token

class NumberLiteral extends Literal
	constructor: (@pos, @value) ->

	show: ->
		@value.toString()

	toJS: ->
		@value.toString()

class JavascriptLiteral extends Literal
	constructor: (@pos, @text) ->

	show: ->
		"`#{@text}`"

	toJS: ->
		"(#{@text})"

class StringLiteral extends Literal
	constructor: (@pos, @text) ->
		type @pos, Pos
		type @text, String

	show: ->
		type @text, String
		@toJS()

	toJS: ->
		type @text, String
		"'#{@text.escapeToJS()}'"

class Special extends Token
	constructor: (@pos, @kind) ->
		type @pos, Pos
		type @kind, String

	show: ->
		x =
			if @kind == '\n'
				'\\n'
			else
				@kind
		"!#{x}!"

class Use extends Token
	constructor: (@pos, @used) ->
		type @used, String

	show: ->
		"<use #{@used}>"


module.exports =
	Token: Token
	Name: Name
	Group: Group
	Literal: Literal
	NumberLiteral: NumberLiteral
	JavascriptLiteral: JavascriptLiteral
	StringLiteral: StringLiteral
	Special: Special
	Use: Use
	nl: (token) ->
		token instanceof Special and token.kind == '\n'
	bar: (token) ->
		token instanceof Special and token.kind == '|'
	dotLikeName: (token) ->
		token instanceof Name and ['.x', '.x_'].contains token.kind
	normalName: (token) ->
		token instanceof Name and token.kind == 'x'
	typeName: (token) ->
		token instanceof Name and token.kind == ':x'
	curlied: (token) ->
		token instanceof Group and token.kind == '{'
