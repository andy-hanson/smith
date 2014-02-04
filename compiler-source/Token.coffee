Pos = require './compile-help/Pos'
{ cCheck } = require './compile-help/✔'
keywords = require './compile-help/keywords'
{ check, type } = require './help/✔'
{ last } = require './help/list'
{ escapeToJS, indented, startsWith } = require './help/str'

class Token
	toString: ->
		"#{@show()}@#{@pos}"

	inspect: ->
		@toString()

class Name extends Token
	@kinds = ['x', '_x', 'x_', '.x', '.x_', '@x', ':x', '‣x', '...x']

	constructor: (@pos, @text, @kind) ->
		type @pos, Pos, @text, String

		check (@kind in Name.kinds), =>
			"Name kind #{@kind} not in #{Name.kinds}"

	show: ->
		"<#{@kind} #{@text}>"


class Group extends Token
	constructor: (openPos, closePos, @kind, @body) ->
		type openPos, Pos, closePos, Pos, @kind, String, body, Array
		@pos =
			openPos

	show: ->
		"'#{@kind}'<#{@body}>"

	@match =
		'(': ')'
		'→': '←'
		'"': '"'

class Literal extends Token

class NumberLiteral extends Literal
	constructor: (@pos, @value) ->

	show: ->
		@value.toString()

	toJS: ->
		if startsWith @value, '-'
			"(#{@value})"
		else
			@value.toString()

class JavascriptLiteral extends Literal
	constructor: (@pos, @text, @kind) ->
		type @pos, Pos, @text, String, @kind, String

	show: ->
		"`#{@text}`"

	toJS: (context) ->
		type context, (require './Expression').Context

		switch @kind
			when 'indented'
				indented @text, context.indent
			when 'plain'
				"(#{@text})"
			when 'special'
				@text
			else
				fail()

class StringLiteral extends Literal
	constructor: (@pos, @text) ->
		type @pos, Pos, @text, String

	show: ->
		@toJS()

	toJS: ->
		"'#{escapeToJS @text}'"

class Special extends Token
	constructor: (@pos, @kind) ->
		type @pos, Pos, @kind, String

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
		cCheck (not ('.' in @used)), @pos,
			"Use (#{@used}) should not include '.'"

	lazy: ->
		@kind == 'use'

	show: ->
		"<use #{@used}>"

	shortName: ->
		last (@used.split '/')

class MetaText extends Token
	constructor: (@pos, @kind, @text) ->
		type @pos, Pos
		check @kind in keywords.metaText
		type @text, Token # string literal or interpolated group

	show: ->
		"<MetaText #{@kind}>"

class Def extends Token
	constructor: (@pos, @name, @name2) ->
		type @pos, Pos, @name, String, @name2, String
		check startsWith @name, "‣"

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
		token instanceof Name and token.kind in [ '.x', '@x', '.x_' ]
	plainName: (token) ->
		token instanceof Name and token.kind == 'x'
	typeName: (token) ->
		token instanceof Name and token.kind == ':x'
	ellipsisName: (token) ->
		token instanceof Name and token.kind == '...x'
	indented: (token) ->
		token instanceof Group and token.kind == '→'
	square: (token) ->
		token instanceof Group and token.kind == '['
	metaGroup: (token) ->
		token instanceof Group and token.kind in keywords.metaFun
	indentedJS: (token) ->
		token instanceof JavascriptLiteral and token.kind == 'indented'
	defLocal: (token) ->
		token instanceof Special and token.kind in [ '∙', '∘' ]
	super: (token) ->
		token instanceof Use and token.kind == 'super'
	it: (token) ->
		token instanceof Special and token.kind == 'it'
