Pos = require './Pos'
{ cCheck } = require './CompileError'
keywords = require './keywords'

class Token
	toString: ->
		"#{@show()}@#{@pos}"

	inspect: ->
		@toString()

class Name extends Token
	@kinds = ['x', '_x', 'x_', '.x', '.x_', '@x', ':x', '‣x', '...x']

	constructor: (@pos, @text, @kind) ->
		type @pos, Pos
		type @text, String

		check (Name.kinds.contains @kind), =>
			"Name kind #{@kind} not in #{Name.kinds}"

	show: ->
		"<#{@kind} #{@text}>"


class Group extends Token
	constructor: (openPos, closePos, open, @body) ->
		type openPos, Pos
		type closePos, Pos
		type open, String
		type body, Array

		@kind =
			if open == '→'
				'{'
			else
				open
		@pos =
			openPos

	show: ->
		"'#{@kind}'<#{@body}>"

	@match =
		'(': ')'
		'[': ']'
		'{': '}'
		'→': '←'
		'"': '"'

class Literal extends Token

class NumberLiteral extends Literal
	constructor: (@pos, @value) ->

	show: ->
		@value.toString()

	toJS: ->
		if @value.startsWith '-'
			"(#{@value})"
		else
			@value.toString()

class JavascriptLiteral extends Literal
	constructor: (@pos, @text, @kind) ->
		type @pos, Pos
		type @text, String
		type @kind, String

	show: ->
		"`#{@text}`"

	toJS: (context) ->
		type context, (require './Expression').Context

		switch @kind
			when 'indented'
				@text.indented context.indent
			when 'plain'
				"(#{@text})"
			when 'special'
				@text
			else
				fail

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
	constructor: (@pos, @used, @kind) ->
		type @pos, Pos
		type @used, String
		type @kind, String

	lazy: ->
		@kind == 'use'

	show: ->
		"<use #{@used}>"

	shortName: ->
		name =
			(@used.split '/').last()
		cCheck (not name.contains '.'), @pos,
			'Local used should not have extension'
		name

class MetaText extends Token
	constructor: (@pos, @kind, @text) ->
		type @pos, Pos
		check keywords.metaText.contains @kind
		type @text, Token # string literal or interpolated group

	show: ->
		"<MetaText #{@kind}>"

class Def extends Token
	constructor: (@pos, @name, @name2) ->
		type @pos, Pos
		type @name, String
		type @name2, String
		check @name.startsWith "‣"

	show: ->
		"<Def #{@name} #{@name2}>"

module.exports =
	Def: Def
	Token: Token
	Name: Name
	Group: Group
	Literal: Literal
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
		token instanceof Name and token.kind.isAny '.x', '@x', '.x_'
	plainName: (token) ->
		token instanceof Name and token.kind == 'x'
	typeName: (token) ->
		token instanceof Name and token.kind == ':x'
	ellipsisName: (token) ->
		token instanceof Name and token.kind == '...x'
	curlied: (token) ->
		token instanceof Group and token.kind == '{'
	square: (token) ->
		token instanceof Group and token.kind == '['
	metaGroup: (token) ->
		token instanceof Group and keywords.metaFun.contains token.kind
	indentedJS: (token) ->
		token instanceof JavascriptLiteral and token.kind == 'indented'
	defLocal: (token) ->
		token instanceof Special and token.kind.isAny '∙', '∘'
	super: (token) ->
		token instanceof Use and token.kind == 'super'
	it: (token) ->
		token instanceof Special and token.kind == 'it'
