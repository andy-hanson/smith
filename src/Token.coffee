Pos = require './Pos'

class Token
	toString: ->
		"#{@show()}@#{@pos}"

	inspect: ->
		@toString()

class Name extends Token
	@kinds = ['x', '_x', 'x_', '.x', '.x_', ',x', ':x', '‣x']

	constructor: (@pos, @text, @kind) ->
		type @pos, Pos
		type @text, String

		check (Name.kinds.contains @kind), =>
			"Name kind #{@kind} not in #{Name.kinds}"

	show: ->
		"<#{@kind} #{@text}>"


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
		"#{@kind}#{@body}#{Group.match[@kind]}"

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

class Meta extends Token

class MetaText extends Meta
	constructor: (@pos, @kind, @text) ->
		type @pos, Pos
		check ['doc', 'how'].contains @kind
		type @text, Token

	show: ->
		"<MetaText #{@kind}>"

class Def extends Token
	constructor: (@pos, @name, @name2) ->
		type @pos, Pos
		type @name, String
		type @name2, String
		check @name.startsWith "‣"

	show: ->
		"<Def @def @name>"

module.exports =
	Def: Def
	Token: Token
	Name: Name
	Group: Group
	Literal: Literal
	Meta: Meta
	MetaText: MetaText
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
		token instanceof Name and ['.x', ',x', '.x_'].contains token.kind
	normalName: (token) ->
		token instanceof Name and token.kind == 'x'
	typeName: (token) ->
		token instanceof Name and token.kind == ':x'
	curlied: (token) ->
		token instanceof Group and token.kind == '{'
