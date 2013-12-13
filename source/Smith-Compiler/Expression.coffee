{ SourceNode } = require 'source-map'
T = require './Token'
Pos = require './Pos'
mangle = require './mangle'
AllModules = require './AllModules'

###
All must have @pos
All must have compile (produces an array)
###
class Expression
	inspect: ->
		@toString()

	nodeWrap: (chunk, fileName) ->
		type fileName, String

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

		@nodeWrap chunk, fileName


class DefLocal extends Expression
	constructor: (@local, @value) ->
		type @local, Local
		type @value, Expression
		{ @pos } = @local

	toString: ->
		"<DefLocal #{@local.text} {#{@value.toString()}}>"

	compile: (fileName, indent) ->
		newIndent =
			indent + '\t'
		name =
			@local.toNode fileName, indent
		inner =
			if @value instanceof Block
				@value.toValue fileName, newIndent
			else
				@value.toNode fileName, newIndent
		val =
			if @local.lazy
				[ '_l(this, function() { return ', inner, ' })' ]
			else
				inner
		check =
			if @local.tipe?
				[ ';\n', indent, @local.typeCheck fileName, indent ]
			else
				''

		[ 'var ', name, '=\n',
			newIndent, val, check ]


class Block extends Expression
	constructor: (@pos, @subs) ->
		type @pos, Pos
		type @subs, Array

		if @subs.isEmpty()
			@subs.push new Null @pos

	toString: ->
		'<BLOCK ' + (@subs.join '\n').indent() + '>\n'

	toValue: (fileName, indent) ->
		if @subs.length == 1 and not @subs[0] instanceof DefLocal
			@subs[0].toNode fileName, indent
		else
			newIndent = indent + '\t'
			x =
				[ '_f(this, function() {\n',
					newIndent,
					(@toNode fileName, newIndent),
					'\n', indent,
					'})()' ]
			@nodeWrap x, fileName

	###
	When nothing is returned.
	###
	noReturn: (fileName, indent) ->
		parts =
			@subs.map (sub) ->
				sub.toNode fileName, indent
		parts.interleave ";\n#{indent}"

	###
	Usual compile, where the last line returns.
	###
	compile: (fileName, indent) ->
		[ allButLast, last ] =
			@subs.allButAndLast()

		compiled =
			allButLast.map (sub) -> sub.toNode fileName, indent

		lastCompiled =
			@compileLast fileName, indent, (x) ->
				[ 'return ', x ]

		compiled.push lastCompiled

		compiled.interleave ";\n#{indent}"

	toMakeRes: (fileName, indent) ->
		[ allButLast, last ] =
			@subs.allButAndLast()

		compiled =
			allButLast.map (sub) -> sub.toNode fileName, indent

		lastCompiled =
			@compileLast fileName, indent, (x) ->
				[ 'var res =\n', indent + '\t', x, ';' ]

		compiled.push lastCompiled

		x =
			compiled.interleave ";\n#{indent}"

		@nodeWrap x, fileName

	compileLast: (fileName, indent, doIfNotSpecial) ->
		last = @subs.last()

		node = last.toNode fileName, indent

		if last instanceof Literal and T.indentedJS last.literal
			node
		else if last instanceof DefLocal
			access =
				new LocalAccess @pos, last.local
			accessNode =
				doIfNotSpecial access.toNode fileName, indent
			[ node, ';\n', indent, accessNode ]
		else
			doIfNotSpecial node

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

	@me = (pos, verb, args) ->
		type pos, Pos
		type verb, String
		type args, Array
		verb =
			new T.Name pos, verb, '.x'
		new Call (new Me pos), verb, args

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

class Meta extends Expression
	constructor: (@pos) ->
		type @pos, Pos

	@all =
		[ 'doc', 'eg', 'how' ]

	compile: (fileName, indent) ->
		newIndent = indent + '\t'

		exist =
			Meta.all.containsWhere (name) =>
				@[name]?

		if exist
			parts = []

			Meta.all.forEach (name) =>
				val =
					@[name]
				if val?
					part =
						switch name
							when 'doc', 'how'
								val.toNode fileName, indent
							when 'eg'
								#(FunDef.plain val).toNode fileName, newIndent
								newNewIndent = newIndent + '\t'
								body =
									val.noReturn fileName, newNewIndent
								[ '_f(this, function() {\n', newNewIndent, body, '\n', newIndent, '})' ]
							else
								fail()

					parts.push [ '_', name, ': ', part ]

			body =
				parts.interleave ",\n#{newIndent}"

			[ '{\n', newIndent, body, '\n', indent, '}' ]
		else
			'{}'

class FunDef extends Expression
	constructor: (@pos, @meta, @tipe, @args, @body) ->
		type @pos, Pos
		type @meta, Meta
		type @tipe, Expression if @tipe?
		type @args, Array
		if @body?
			if @body instanceof T.JavascriptLiteral
				check @body.kind == 'indented'
			else
				type @body, Block

	toString: ->
		"{#{@args} ->\n #{@body.toString().indent()}}"

	compile: (fileName, indent) ->
		maybeMeta = (kind) =>
			if @meta?[kind]?
				[ (@meta[kind].noReturn fileName, newIndent), '\n', newIndent ]
			else
				''

		newIndent = indent + '\t'

		argNames =
			(@args.map (arg) -> arg.toNode fileName, newIndent).interleave ', '
		argChecks =
			@args.map (arg) -> arg.typeCheck fileName, newIndent
		inCond =
			maybeMeta 'in'
		body =
			if @body?
				@body.toMakeRes fileName, newIndent
			else
				"var res = null;"
		outCond =
			maybeMeta 'out'
		typeCheck = do =>
			loc =
				Local.res @pos, @tipe
			loc.typeCheck fileName, newIndent
		meta =
			@meta.toNode fileName, indent

		[ '_f(this, function(', argNames, ') {',
			'\n', newIndent,
			argChecks,
			inCond,
			body,
			'\n', newIndent,
			typeCheck,
			outCond,
			'return res\n',
			indent, '}, ',
			meta, ')' ]

	@plain = (body) ->
		type body, Block

		new FunDef body.pos, (new Meta body.pos), null, [], body

###
_func
###
class ItFunDef extends Expression
	constructor: (@name) ->
		{ @pos } = @name

	compile: (fileName, indent) ->
		[ "(function(it) { return _c(it, '", @name.text,
		"', Array.prototype.slice.call(arguments, 1)) })" ]

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

	compile: (fileName, indent) ->
		[ (@literal.toJS fileName, indent) ]


class LocalAccess extends Expression
	constructor: (@pos, @local) ->
		type @pos, Pos
		type @local, Local

	toString: ->
		@local.toString()

	compile: ->
		m = mangle @local.text
		if @local.lazy
			"#{m}()"
		else
			m

class Local extends Expression
	constructor: (name, @tipe, @lazy) ->
		type name, T.Name
		type @tipe, Expression if @tipe?
		type @lazy, Boolean
		{ @text, @pos } = name

	toString: ->
		"<#{@text}>"

	compile: ->
		mangle @text

	typeCheck: (fileName, indent) ->
		if @tipe?
			tipe =
				@tipe.toNode fileName, indent
			nameLit =
				new Literal new T.StringLiteral @pos, @text
			name =
				nameLit.toNode fileName, indent
			[ tipe, '.check(', name, ', ', @compile(), ')\n', indent ]
		else
			''

	@eager = (name, tipe) ->
		new Local name, tipe, no

	@res = (pos, tipe) =>
		@eager (new T.Name pos, 'res', 'x'), tipe

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


class Use extends Expression
	constructor: (use, fileName, allModules) ->
		type use, T.Use
		type fileName, String
		type allModules, AllModules

		{ @pos } = use
		localName =
			(use.used.split '/').last()
		@fullName =
			allModules.get use.used, @pos, fileName
		@local =
			new Local (new T.Name @pos, localName, 'x'), null, use.lazy

	toString: ->
		"<use #{@local.text}>"

	compile: (fileName, indent) ->
		val =
			new Literal new T.JavascriptLiteral @pos,
				"require('#{@fullName}')", 'special'

		val.compile fileName, indent


class Null extends Expression
	constructor: (@pos) ->

	toString: ->
		"null"

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
	Block: Block
	Call: Call
	DefLocal: DefLocal
	Expression: Expression
	FunDef: FunDef
	ItFunDef: ItFunDef
	BoundFun: BoundFun
	Literal: Literal
	Local: Local
	LocalAccess: LocalAccess
	Me: Me
	Meta: Meta
	Property: Property
	Quote: Quote
	Use: Use
	Null: Null
	Parend: Parend
