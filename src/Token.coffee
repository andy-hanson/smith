Pos = require './Pos'

class Token
	toString: ->
		"#{@show()}@#{@pos}"

	inspect: ->
		@toString()

class Name extends Token
	@types = ['x', '_x', 'x_', '.x', '.x_']

	constructor: (@pos, @text, @type) ->
		check (Name.types.contains @type), =>
			"Type #{@type} not in #{Name.types}"

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

		@type =
			if open == '->'
				'{'
			else
				open
		@pos = openPos

	show: ->
		"#{@type}#{@body}#{Group.match[@type]}"

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
	constructor: (@pos, @type) ->

	show: ->
		x =
			if @type == '\n'
				'\\n'
			else
				@type
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
		token instanceof Special and token.type == '\n'
	bar: (token) ->
		token instanceof Special and token.type == '|'
	dotLikeName: (token) ->
		token instanceof Name and ['.x', '.x_'].contains token.type
	normalName: (token) ->
		token instanceof Name and token.type == 'x'
	curlied: (token) ->
		token instanceof Group and token.type == '{'
