{ SourceNode } = require 'source-map'
T = require './Token'
Pos = require './Pos'
mangle = require './mangle'
keywords = require './keywords'
{ countWhere } = require './helpers'

class Context
	constructor: (@options, @fileName, @indent) ->
		type @options, require './Options'
		type @fileName, String
		type @indent, String

	indented: (n = 1) ->
		new Context @options, @fileName, "#{'\t'.repeated n}#{@indent}"

###
All must have @pos
All must have compile (produces an array)
###
class Expression
	inspect: ->
		@toString()

	nodeWrap: (chunk, context) ->
		type context, Context
		type context.fileName, String

		new SourceNode \
			@pos.line,
			@pos.column,
			context.fileName,
			chunk

	toNode: (context) ->
		type @pos, Pos
		type context, Context

		chunk =
			@compile context

		@nodeWrap chunk, context

class Trait extends Expression
	constructor: (@use) ->
		type use, Use
		{ @pos } = use

	compile: (context) ->
		def = new DefLocal @use.local, @use
		trait = Call.me @pos, 'trait', [ @use.local ]
		[	(def.toNode context),
			'\n', context.indent,
			(trait.toNode context) ]

class DefLocal extends Expression
	constructor: (@local, @value) ->
		type @local, Local
		type @value, Expression
		{ @pos } = @local

	toString: ->
		"<DefLocal #{@local.name} {#{@value.toString()}}>"

	needsToCompile: ->
		@local.everUsed() or not @local.lazy

	compile: (context) ->
		if @needsToCompile()
			name =
				@local.toNode context
			val =
				if @local.lazy
					inner =
						if @value instanceof Block
							@value.toNode context.indented 2
						else
							[ 'return ', (@value.toNode context.indented 2), ';' ]
					[ '_l(this, function() {\n\t\t', context.indent, inner, '\n\t', context.indent, '})' ]
				else
					@value[if @value instanceof Block then 'toValue' else 'toNode'] context

			check =
				if context.options.checks() and @local.tipe?
					[ ';\n', context.indent, @local.typeCheck context ]
				else
					''

			[ 'var ', name, ' =\n\t', context.indent, val, check ]
		else
			'' #"/* need not compile local #{@local.name}*/"

	@fromUse = (use) ->
		new DefLocal use.local, use

class Block extends Expression
	constructor: (@pos, @subs) ->
		type @pos, Pos
		type @subs, Array

		if @subs.isEmpty()
			@subs.push new Null @pos

	toString: ->
		'<BLOCK ' + (@subs.join '\n').indent() + '>\n'

	toValue: (context) ->
		if @subs.length == 1 and not (@subs[0] instanceof DefLocal)
			@subs[0].toNode context
		else
			x =
				[ '_f(this, function() {\n\t',
					context.indent,
					(@toNode context.indented()),
					'\n', context.indent, '})()' ]
			@nodeWrap x, context

	filteredSubs: (subs, context) ->
		out = []
		subs.forEach (sub) ->
			compiled = sub.compile context
			if compiled != ''
				out.push sub.nodeWrap compiled, context
		out


	###
	When nothing is returned.
	###
	noReturn: (context) ->
		@filteredSubs(@subs, context).interleave ";\n#{context.indent}"

	###
	Usual compile, where the last line returns.
	###
	compile: (context) ->
		@compileWithLast context, (x) ->
			[ 'return ', x, ';' ]

	toMakeRes: (context) ->
		x =
			@compileWithLast context, (x) ->
				[ 'var res = ', x, ';' ]

		@nodeWrap x, context

	compileWithLast: (context, doIfNotSpecial) ->
		last =
			@subs.last()
		node =
			last.toNode context

		lastNode =
			if last instanceof Literal and T.indentedJS last.literal
				node
			else if last instanceof DefLocal
				access =
					new LocalAccess @pos, last.local
				accessNode =
					doIfNotSpecial access.toNode context
				[ node, ';\n', context.indent, accessNode ]
			else
				[ doIfNotSpecial node, ';' ]

		compiled =
			@filteredSubs @subs.allButLast(), context
		compiled.push lastNode

		compiled.interleave ";\n#{context.indent}"

class Call extends Expression
	constructor: (@subject, @verb, @args) ->
		check arguments.length == 3
		type @subject, Expression
		type @verb, T.Name
		check @verb.kind == '.x'
		type @args, Array

		@args.forEach (arg) ->
			type arg, Expression
		@pos = @verb.pos

	toString: ->
		"#{@subject}.#{@verb.text}(#{@args})"

	compile: (context) ->
		subject =
			@subject.toNode context

		hasMany =
			@args.containsWhere (x) ->
				x instanceof ManyArgs

		if hasMany
			parts =
				@args.map (arg) ->
					if arg instanceof ManyArgs
						[ arg.value.toNode context ]
					else
						[ '[', (arg.toNode context), ']' ]

			args =
				[ '[', (parts.interleave ', '), ']' ]

			[ '_c(', subject, ", '", @verb.text, "', ", args, ')' ]
		else
			parts =
				@args.map (x) ->
					x.toNode context
			args =
				parts.interleave ', '

			[ subject, "['", @verb.text, "'](", args, ')' ]

	@me = (pos, verb, args) ->
		verb = new T.Name pos, verb, '.x'
		new Call (new Me pos), verb, args

	@of = (expr, args) ->
		verb = new T.Name expr.pos, 'of', '.x'
		new Call expr, verb, args

	@noArgs = (subject, verb) ->
		new Call subject, verb, []

class Property extends Expression
	constructor: (@subject, @prop) ->
		type @subject, Expression
		type @prop, T.Name
		{ @pos } = @prop

	toString: ->
		"#{@subject},#{@prop.text}"

	compile: (context) ->
		[ (@subject.toNode context), "['", @prop.text, "']" ]

	@me = (pos, name) ->
		new Property (new Me pos), name

class Meta extends Expression
	constructor: (@pos) ->
		type @pos, Pos

	@all =
		[ 'eg', 'sub-eg' ].concat keywords.metaText

	make: (fun, context) ->
		parts = []

		Meta.all.forEach (name) =>
			if context.options.meta() or name == '_arguments'
				val =
					@[name]
				if val?
					part =
						if keywords.metaFun.contains name
							(FunDef.body val).toNode context.indented()
						else
							val.toNode context

					parts.push [ "'_", name, "': ", part ]

		arg = (x) ->
			type x, Local
			x.toMeta context
		args = (x) ->
			(x.map arg).interleave ', '
		rest = (name, x) ->
			if fun[x]?
				parts.push [ "'_#{name}': ", arg fun[x] ]

		if fun.optArgs?
			parts.push [ '_options: [', (args fun.optArgs), ']' ]
		rest 'rest-option', 'optRest'
		parts.push [ '_arguments: [', (args fun.args), ']' ]
		rest 'rest-argument', 'maybeRest'

		body =
			parts.interleave ",\n\t#{context.indent}"

		[ ', function() { return {\n\t', context.indent, body, '\n', context.indent, '}; }' ]


	toString: ->
		"doc: #{@doc}; eg: #{@eg}; how: #{@how}; sub-eg: #{@['sub-eg']}"

class FunDef extends Expression
	constructor: (@pos, @meta, @tipe, @args, @maybeRest, @body) ->
		check arguments.length == 6
		type @pos, Pos
		type @meta, Meta if @meta?
		type @tipe, Expression if @tipe?
		type @args, Array # of Locals
		type @maybeRest, Local if @maybeRest?
		type @body, Block if @body?

	toString: ->
		"{#{@args} ->\n #{@body?.toString().indent()}}"

	isOpts: (arg) ->
		type arg, Local
		arg.name.endsWith '~'


	optLessAssignArgs: (context) ->
		getRest = (rest, argsRendered, nArgs, end) =>
			if rest?
				get =
					jsLiteral @pos,
						"global.Array.prototype.slice.call(#{argsRendered}, #{nArgs})"

				[ ((new DefLocal rest, get).toNode context), end ]
			else if context.options.checks()
				"_n(#{argsRendered}, #{nArgs})#{end}"
			else
				''

		checks =
			if context.options.checks()
				@args.map (arg) ->
					arg.typeCheck context
				.filter (x) ->
					x != ''
			else
				[]
		rest =
			getRest @maybeRest, 'arguments', @args.length, ";\n#{context.indent}"

		[ (checks.interleavePlus "\n#{context.indent}"), rest ]

	optFullAssignArgs: (context, nOpts) ->
		if @maybeRest?
			cFail @pos, "Can not have both optional and rest arguments"

		nNormal = @args.length - nOpts

		optIndex = 0
		assigns = @args.map (arg) =>
			inside =
				arg.typeCheckValue context, (Literal.JS arg.pos, '_r[_i++]')

			assigned =
				if @isOpts arg
					nth = optIndex + nNormal
					optIndex += 1
					[ '(_l > ', "#{nth}", ') ? _p.Some.of(', inside, ') : _p.None' ]
				else
					inside
			[ (arg.toNode context), ' = ', assigned ]

		x = ",\n\t#{context.indent}"
		assigns = assigns.interleave x

		[ 'var _i = 0, _r = arguments, _l = _r.length', x, assigns, ';\n', context.indent ]

	assignArgs: (context) ->
		nOpts =
			countWhere @args, (arg) =>
				@isOpts arg

		if nOpts == 0
			@optLessAssignArgs context
		else
			@optFullAssignArgs context, nOpts

	compile: (context) ->
		maybeMeta = (kind) =>
			if @meta?[kind]?
				[ (@meta[kind].noReturn context), '\n', context.indent ]
			else
				''
		needRes =
			meta?.out? or @tipe?

		argNames =
			(@args.map (arg) -> arg.toNode context.indented()).interleave ', '
		assignArgs =
			@assignArgs context.indented()
		inCond =
			maybeMeta 'in'
		body =
			if @body?
				if needRes
					[ @body.toMakeRes context.indented() ]
				else
					[ @body.toNode context.indented() ]
			else
				"\tvar res = null;"
		outCond =
			maybeMeta 'out'
		typeCheck = do =>
			if context.options.checks()
				loc =
					Local.res @pos, @tipe
				loc.typeCheck context.indented()
			else
				''
		meta =
			if @meta?
				@meta.make @, context
			else
				''
		res =
			if needRes
				[ 'return res;' ]
			else
				''

		maybe = (x) ->
			if x == ''
				x
			else
				[ '\n\t', context.indent, x ]

		[ '_f(this, function(', argNames, ') {',
			maybe(assignArgs),
			maybe(inCond),
			body,
			(maybe typeCheck),
			(maybe outCond),
			(maybe res),
			'\n', context.indent,
			'}', meta, ')' ]

	@plain = (pos, meta, args, body) ->
		new FunDef pos, meta, null, args,  null, body

	###
	Just the body, no meta, no args
	###
	@body = (body) ->
		@plain body.pos, null, [], body

###
_func
(unrelated to keyword 'it')
###
class ItFunDef extends Expression
	constructor: (@name) ->
		{ @pos } = @name

	compile: (context) ->
		[ "_it('", @name.text, "')" ]

###
func_
.func_
###
class BoundFun extends Expression
	constructor: (@subject, @name) ->
		type @subject, Expression
		type @name, T.Name
		{ @pos } = @name

	compile: (context) ->
		[ '_b(', (@subject.toNode context), ", '", @name.text, "')" ]

	@me = (name) ->
		new BoundFun (new Me name.pos), name


class Literal extends Expression
	constructor: (@literal) ->
		type @literal, T.Literal
		{ @pos } = @literal

	toString: ->
		"<#{@literal}>"

	compile: (context) ->
		@literal.toJS context

	@JS = (pos, text) ->
		type pos, Pos
		type text, String
		new Literal new T.JavascriptLiteral pos, text, 'special'

class Local extends Expression
	constructor: (name, @tipe, @lazy) ->
		type name, T.Name
		type @tipe, Expression if @tipe?
		type @lazy, Boolean
		@name = name.text
		{ @pos } = name
		@_everUsed = no

	isUsed: ->
		@_everUsed = yes

	everUsed: ->
		@_everUsed

	toString: ->
		"<#{@name}:#{@pos}>"

	compile: ->
		mangle @name

	typeCheck: (context) ->
		if @tipe?
			[ (@typeCheckValue context, @), ';' ]
		else
			''

	typeCheckValue: (context, checked) ->
		type checked, Expression

		if @tipe?
			tipe =
				@tipe.toNode context
			nameLit =
				new Literal new T.StringLiteral @pos, @name
			name =
				nameLit.toNode context
			checkedNode =
				checked.toNode context
			[ tipe, '.check(', name, ', ', checkedNode, ')' ]
		else
			checked.toNode context

	toMeta: (context) ->
		tipe =
			if @tipe?
				[ ", ", (@tipe.toNode context) ]
			else
				''

		@nodeWrap [ "_a('", @name, "'", tipe, ')' ], context

	@it = (pos) ->
		@eager new T.Name pos, 'it', 'x'

	@eager = (name, tipe) ->
		new Local name, tipe, no

	@res = (pos, tipe) =>
		@eager (new T.Name pos, 'res', 'x'), tipe



class LocalAccess extends Expression
	constructor: (@pos, @local) ->
		type @pos, Pos
		type @local, Local
		@local.isUsed()

	toString: ->
		@local.toString()

	compile: ->
		m = mangle @local.name
		if @local.lazy
			"#{m}()"
		else
			m
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

	compile: (context) ->
		nodes =
			@parts.map (part) ->
				part.toNode context

		[ '_s(', (nodes.join ', '), ')' ]

###
Represents requiring something.
Does NOT represent defining the local.
###
class Use extends Expression
	constructor: (use, fileName, allModules) ->
		type use, T.Use
		type fileName, String
		type allModules, require './AllModules'
		{ @pos, @kind } = use
		name =
			new T.Name @pos, use.shortName(), 'x'
		@local =
			new Local name, null, use.lazy()
		@fullName =
			allModules.get use.used, @pos, fileName

	toString: ->
		"<#{@kind} #{@fullName}>"

	compile: (context) ->
		val =
			new Literal new T.JavascriptLiteral @pos,
				"require('#{@fullName}')", 'special'

		val.compile context

	# used in type-level eg
	@typeLocal = (typeName, fileName, allModules) ->
		x = new T.Use Pos.start, typeName, 'use!'
		new Use x, fileName, allModules


class Null extends Expression
	constructor: (@pos) ->

	toString: ->
		"null"

	compile: ->
		[ 'null' ]


class Parend extends Expression
	constructor: (@content) ->
		type @content, Expression
		{ @pos } = @content

	toString: ->
		"(#{@content})"

	compile: (context) ->
		@content.compile context

jsLiteral = (pos, text) ->
	new Literal new T.JavascriptLiteral pos, text, 'special'

class ManyArgs extends Expression
	constructor: (@value) ->
		type @value, Expression
		@pos = @value.pos

	compile: ->
		throw new Error "Should not be compiling ManyArgs"

	toString: ->
		"...#{@value}"

module.exports =
	Block: Block
	Call: Call
	Context: Context
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
	Trait: Trait
	jsLiteral: jsLiteral
	ManyArgs: ManyArgs
