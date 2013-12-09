SourceNode = (require 'source-map').SourceNode
T = require './Token'
Pos = require './Pos'
mangle = require './mangle'

###
All must have @pos
All must have compile (produces an array)
###
class Expression
	inspect: ->
		@toString()

	nodeWrap: (chunk, fileName) ->
		new SourceNode \
			@pos.line,
			@pos.column,
			fileName,
			chunk

	toNode: (fileName, indent) ->
		type @pos, Pos
		type fileName, String
		type indent, String

		chunk =
			@compile fileName, indent

		@nodeWrap chunk

	eachSub: (f) ->
		f @
		(Object.keys @).forEach (key) =>
			value = @[key]
			#if value instanceof Expression
			#	value.eachSub f
			if value instanceof Array
				value.forEach (sub) =>
					sub.eachSub f

class Arguments extends Expression
	constructor: (@pos) ->

	compile: (fileName, indent) ->
		'Array.prototype.slice.call(arguments)'

class VoidExpression extends Expression


class DefLocal extends VoidExpression
	constructor: (@local, @value) ->
		type @local, Local
		type @value, Expression
		{ @pos } = @local

	toString: ->
		"<. #{@local.text} {#{@value.toString()}}>"

	compile: (fileName, indent) ->
		newIndent = indent + '\t'
		inner =
			if @value instanceof Block
				@value.toValue fileName, newIndent
			else
				@value.toNode fileName, newIndent

		[ 'var ', (@local.toNode fileName, indent),
			' =\n', newIndent, inner,
			';\n', indent, (@local.typeCheck fileName, indent) ]



class Block extends Expression
	constructor: (@pos, @subs) ->
		type @pos, Pos
		type @subs, Array

		if subs.isEmpty() or subs.last() instanceof VoidExpression
			@subs.push new Void @pos

	toString: ->
		'<BLOCK ' + (@subs.join ';\n').indent() + '>\n'

	toValue: (fileName, indent) ->
		if @subs.length == 1
			@subs[0].toNode fileName, indent
		else
			newIndent = indent + '\t'
			x =
				[ '_f(this, function() {\n',
					(@toNode fileName, newIndent),
					'\n', indent,
					'})()' ]
			@nodeWrap x

	compile: (fileName, indent) ->
		[ allButLast, last ] =
			@subs.allButAndLast()

		compiled =
			allButLast.map (sub) -> sub.toNode fileName, indent

		lastCompiled =
			[ 'return ', (last.toNode fileName, indent), ';' ]

		compiled.push lastCompiled

		[indent].concat compiled.interleave (';\n' + indent)


	toMakeRes: (fileName, indent) ->
		[ allButLast, last ] =
			@subs.allButAndLast()

		compiled =
			allButLast.map (sub) -> sub.toNode fileName, indent

		lastCompiled =
			[ 'var res = \n', indent + '\t', (last.toNode fileName, indent), ';' ]

		compiled.push lastCompiled

		x =
			[indent].concat compiled.interleave ";\n#{indent}"

		@nodeWrap x

class Call extends Expression
	constructor: (@subject, @verb, @args) ->
		type @subject, Expression
		type @verb, T.Name
		check @verb.kind == '.x'
		type @args, Array

		@args.forEach (arg) ->
			type arg, Expression
		@pos = @verb.pos

	toString: ->
		"#{@subject}.#{@verb.text}(#{@args})"

	compile: (fileName, indent) ->
		subject =
			@subject.toNode fileName, indent
		nodes =
			@args.map (x) -> x.toNode fileName, indent
		args =
			nodes.interleave ', '

		[ subject, "['", @verb.text, "'](", args, ')' ]

	@me = (verb, args) ->
		type verb, T.Name
		verb =
			new T.Name verb.pos, verb.text, '.x'
		new Call (new Me verb.pos), verb, args

	@of = (expr, args) ->
		type expr, Expression
		verb = new T.Name expr.pos, 'of', '.x'
		new Call expr, verb, args

class Property extends Expression
	constructor: (@subject, @prop) ->
		type @subject, Expression
		type @prop, T.Name
		{ @pos } = @prop

	toString: ->
		"#{@subject},#{@prop.text}"

	compile: (fileName, indent) ->
		[ (@subject.toNode fileName, indent), '.', @prop.text ]


class FunDef extends Expression
	constructor: (@pos, @tipe, @args, @body) ->
		type @pos, Pos
		type @tipe, Expression if @tipe?
		type @args, Array
		type @body, Block

	toString: ->
		"{#{@args} ->\n #{@body.toString().indent()}}"

	compile: (fileName, indent) ->
		newIndent = indent + '\t'

		argNames =
			(@args.map (arg) -> arg.toNode fileName, newIndent).interleave ', '
		argChecks =
			(@args.map (arg) -> arg.typeCheck fileName, newIndent).interleave ";\n#{newIndent}"
		body =
			@body.toMakeRes fileName, newIndent
		typeCheck =
			(new Local (new T.Name @pos, 'res', 'x'), @tipe).typeCheck fileName, indent

		[ '_f(this, function(', argNames, ') {',
			'\n', newIndent,
			argChecks, ';\n',
			body,
			'\n', newIndent,
			typeCheck,
			';\n', newIndent,
			'return res;\n',
			indent, '})' ]

###
_func
###
class ItFunDef extends Expression
	constructor: (@name) ->
		{ @pos } = @name

	compile: (fileName, indent) ->
		[ "(function(it) { return _c(it, '", @name.text,
		"', Array.prototype.slice.call(arguments, 1)); })" ]

###
func_
.func_
###
class BoundFun extends Expression
	constructor: (@subject, @name) ->
		{ @pos } = @name

	compile: (fileName, indent) ->
		[ '_b(', (@subject.toNode fileName, indent), ", '", @name.text, "')" ]

	@me = (name) ->
		new BoundFun (new Me name.pos), name


class Literal extends Expression
	constructor: (@literal) ->
		type @literal, T.Literal
		{ @pos } = @literal

	toString: ->
		"<#{@literal}>"

	compile: ->
		[ @literal.toJS() ]



class Local extends Expression
	constructor: (name, @tipe) ->
		type name, T.Name
		type @tipe, Expression if @tipe?
		{ @text, @pos } = name

	toString: ->
		"<#{@text}>"

	compile: ->
		mangle @text

	typeCheck: (fileName, indent) ->
		###
		f =
			if @tipe?
				[ (@tipe.toNode fileName, indent), '.check(' ]
			else
				'_c('

		name =
			new Literal new T.StringLiteral @pos, @text

		[ f, name.compile(), ', ', @compile(), ')' ]
		###
		if @tipe?
			name =
				new Literal new T.StringLiteral @pos, @text
			[ (@tipe.toNode fileName, indent), '.check(',
				(name.toNode fileName, indent), ', ', @compile(), ')' ]
		else
			''

class Me extends Expression
	constructor: (@pos) ->
		type @pos, Pos

	toString: ->
		'me'

	compile: ->
		'this'


class Quote extends Expression
	constructor: (@pos, @parts) ->
		type @pos, Pos
		type @parts, Array

	toString: ->
		'"' + @parts.join '|' + '"'

	compile: (fileName, indent) ->
		nodes =
			@parts.map (part) ->
				(part.toNode fileName, indent)

		[ '_s(', (nodes.join ', '), ')' ]


class Use extends VoidExpression
	constructor: (use) ->
		type use, T.Use
		localName = (use.used.split '/').last()
		@fullName = use.used
		{ @pos } = use
		@local = new Local new T.Name @pos, localName, 'x'

	toString: ->
		"<use #{@local.text}>"

	compile: (fileName, indent) ->
		val =
			new Literal new T.JavascriptLiteral @pos, "require('#{@fullName}')"

		(new DefLocal @local, val).compile fileName, indent


class Void extends VoidExpression
	constructor: (@pos) ->

	toString: ->
		"<VOID>"

	compile: ->
		[ 'null' ]


class Parend extends Expression
	constructor: (@content) ->
		{ @pos } = @content

	toString: ->
		'(' + @content + ')'

	compile: (fileName, indent) ->
		@content.compile fileName, indent

###
class QuoteExpression extends Expression
	constructor: (quote) ->
		#type quote, Quote
		{ @pos, @text } = quote

	toString: ->
		@compile()

	compile: ->
		'"' + @text + '"'
###

module.exports =
	Arguments: Arguments
	Block: Block
	Call: Call
	DefLocal: DefLocal
	Expression: Expression
	FunDef: FunDef
	ItFunDef: ItFunDef
	BoundFun: BoundFun
	Literal: Literal
	Local: Local
	Me: Me
	Property: Property
	Quote: Quote
	Use: Use
	Void: Void
	Parend: Parend
