{ SourceNode } = require 'source-map'
T = require './Token'
Pos = require './Pos'
mangle = require './mangle'

tab = (indent) ->
	"\t#{indent}"

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

trait = (use) ->
	type use, Use
	{ local, pos } = use
	verb = new T.Name pos, 'trait'
	value = Call.me pos, verb, [ use ]
	new DefLocal local, value

class DefLocal extends Expression
	constructor: (@local, @value) ->
		type @local, Local
		type @value, Expression
		{ @pos } = @local

	toString: ->
		"<DefLocal #{@local.text} {#{@value.toString()}}>"

	compile: (fileName, indent) ->
		newIndent =
			tab indent
		name =
			@local.toNode fileName, indent
		val =
			if @local.lazy
				newNewIndent =
					tab newIndent
				inner =
					if @value instanceof Block
						@value.toNode fileName, newNewIndent
					else
						[ 'return ', (@value.toNode fileName, newNewIndent), ';' ]
				x =
					[ 'function() {\n', newNewIndent, inner, '\n', newIndent, '}' ]
				if @value instanceof Use
					# require is cached anyway
					x
				else
					[ '_l(this, ', x, ')' ]
			else
				if @value instanceof Block
					@value.toValue fileName, newIndent
				else
					@value.toNode fileName, newIndent

		check =
			if @local.tipe?
				[ ';\n', indent, @local.typeCheck fileName, indent ]
			else
				''

		[ 'var ', name, ' =\n', newIndent, val, check ]


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
			newIndent =
				tab indent
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
				[ 'return ', x, ';' ]

		compiled.push lastCompiled

		compiled.interleave ";\n#{indent}"

	toMakeRes: (fileName, indent) ->
		[ allButLast, last ] =
			@subs.allButAndLast()

		compiled =
			allButLast.map (sub) -> sub.toNode fileName, indent

		lastCompiled =
			@compileLast fileName, indent, (x) ->
				[ 'var res =\n', (tab indent), x, ';' ]

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
	constructor: (@subject, @verb, @optionArgs, @args) ->
		type @subject, Expression
		type @verb, T.Name
		check @verb.kind == '.x'
		type @optionArgs, Array
		type @args, Array

		@args.forEach (arg) ->
			type arg, Expression
		@pos = @verb.pos

	toString: ->
		"#{@subject}.#{@verb.text}(#{@args})"

	compile: (fileName, indent) ->
		newIndent =
			tab indent
		subject =
			@subject.toNode fileName, newIndent
		hasMany = (xx) ->
			xx.containsWhere (x) ->
				x instanceof ManyArgs
		if hasMany @args or hasMany @optionArgs
			renderArgs = (args) ->
				parts =
					args.map (arg) ->
						if arg instanceof ManyArgs
							# TODO - to-array
							arg.value.toNode fileName, newIndent
						else
							[ '[', (arg.value.toNode fileName, newIndent), ']' ]
				[ '[', (parts.interleave ', '), ']' ]
			[ '_call(', subject, ", '", @verb.text, "', ",
				(renderArgs @optionArgs), ', ', (renderArgs @args), ')' ]
		else
			nodes =
				@args.map (x) -> x.toNode fileName, newIndent
			args =
				nodes.interleave ', '
			optionArgs =
				if @optionArgs.isEmpty()
					''
				else
					opts =
						(@optionArgs.map (x) -> x.toNode fileName, newIndent).interleavePlus ','
					[ '_opt, [', opts, '], ' ]

			[ subject, "['", @verb.text, "'](", optionArgs, args, ')' ]

	@me = (pos, verb, args) ->
		verb = new T.Name pos, verb, '.x'
		new Call (new Me pos), verb, [], args

	@of = (expr, opts, args) ->
		verb = new T.Name expr.pos, 'of', '.x'
		new Call expr, verb, opts, args

	@noArgs = (subject, verb) ->
		new Call subject, verb, [], []

class Property extends Expression
	constructor: (@subject, @prop) ->
		type @subject, Expression
		type @prop, T.Name
		{ @pos } = @prop

	toString: ->
		"#{@subject},#{@prop.text}"

	compile: (fileName, indent) ->
		[ (@subject.toNode fileName, indent), "['", @prop.text, "']" ]

	@me = (pos, name) ->
		new Property (new Me pos), name

class Meta extends Expression
	constructor: (@pos) ->
		type @pos, Pos

	@all =
		[ 'doc', 'eg', 'how' ]

	make: (fun, fileName, indent) ->
		newIndent = tab indent

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
							(FunDef.body val).toNode fileName, newIndent
						else
							fail()

				parts.push [ '_', name, ': ', part ]

		arg = (x) ->
			type x, Local
			x.toMeta fileName, indent
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
			parts.interleave ",\n#{newIndent}"

		[ ', function() { return {\n', newIndent, body, '\n', indent, '}; }' ]


	toString: ->
		"doc: #{@doc}; eg: #{@eg}; how: #{@how}"

class FunDef extends Expression
	constructor: (@pos, @meta, @tipe, @optArgs, \
			   @optRest, @args, @maybeRest, @body) ->
		type @pos, Pos
		type @meta, Meta
		type @tipe, Expression if @tipe?
		type @optArgs, Array if @optArgs?
		type @optRest, Local if @optRest?
		type @args, Array # of Locals
		type @maybeRest, Local if @maybeRest?
		if @body?
			if @body instanceof T.JavascriptLiteral
				check @body.kind == 'indented'
			else
				type @body, Block

	toString: ->
		"{#{@args} ->\n #{@body?.toString().indent()}}"


	assignArgs: (fileName, indent) ->
		getRest = (maybeRest, argsRendered, nArgs, ignoreOpts) =>
			if @maybeRest?
				get =
					jsLiteral @pos,
						"global.Array.prototype.slice.call(#{argsRendered}, #{nArgs})"
				def =
					new DefLocal maybeRest, get
				def.toNode fileName, indent
			else
				# TODO
				#if ignoreOpts
					# skip first 2
				"_nArgs(#{argsRendered}, #{nArgs})"

		#argChecks =
		#	# TODO: opt args too
		#	@args.map (arg) -> arg.typeCheck fileName, newIndent

		if @optArgs?
			nOpts = @optArgs.length
			newIndent = tab indent

			assign = (arg, args, index, isOpt = no) ->
				val = "#{args}[#{index}]"
				if arg.tipe?
					val = [
						(arg.tipe.toNode fileName, indent),
						".check('#{arg.name}', #{val})"
					]
				if isOpt
					val = [ 'Opt().some(', val, ')' ]

				[ "var #{arg.toNode fileName, indent} = ", val ]

			getOpts =
				for opt, index in @optArgs
					assign opt, "_opts", index, yes

			getArgsIfOpts =
				for arg, index in @args
					assign arg, "arguments", index + 2

			getNoOpts =
				for opt in @optArgs
					[ 'var ', (opt.toNode fileName, indent), ' = Opt().None()' ]

			getNoOptRest =
				if @optRest?
					[ 'var ', (@optRest.toNode fileName, indent),
						' = Opt().None();\n', newIndent ]
				else
					''

			getArgsNoOpts =
				for arg, index in @args
					assign arg, "arguments", index

			nl = "\n#{newIndent}"
			snl = ";#{nl}"

			s = [
				'if (arguments[0] == _opt) {',
					nl, 'var _opts = arguments[1]',
					snl,
					(getOpts.interleavePlus snl),
					(getArgsIfOpts.interleavePlus snl),
					(getRest @optRest, '_opts', nOpts), snl,
					(getRest @maybeRest, 'arguments', @args.length + 2),
				';\n', indent, '} else {', nl,
					(getNoOpts.interleavePlus snl),
					(getArgsNoOpts.interleavePlus snl),
					getNoOptRest,
					(getRest @maybeRest, 'arguments', @args.length),
				';\n', indent, '}'
				]

		else
			[ (getRest @maybeRest, 'arguments', @args.length), ';' ]

	compile: (fileName, indent) ->
		maybeMeta = (kind) =>
			if @meta?[kind]?
				[ (@meta[kind].noReturn fileName, newIndent), '\n', newIndent ]
			else
				''
		newIndent =
			tab indent
		argNames =
			(@args.map (arg) -> arg.toNode fileName, newIndent).interleave ', '
		assignArgs =
			@assignArgs fileName, newIndent
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
			@meta.make @, fileName, indent

		[ '_f(this, function(', argNames, ') {',
			'\n', newIndent,
			assignArgs,
			inCond,
			'\n', newIndent,
			body,
			'\n', newIndent,
			typeCheck,
			outCond,
			'return res;\n',
			indent, '}',
			meta, ')' ]

	@plain = (pos, meta, args, body) ->
		new FunDef pos, meta, null, null, null, args, null, body

	@body = (body) ->
		@plain body.pos, (new Meta body.pos), [], body

###
_func
(unrelated to keyword 'it')
###
class ItFunDef extends Expression
	constructor: (@name) ->
		{ @pos } = @name

	compile: (fileName, indent) ->
		[ "_it('", @name.text, "')" ]

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
		m = mangle @local.name
		if @local.lazy
			"#{m}()"
		else
			m

class Local extends Expression
	constructor: (name, @tipe, @lazy) ->
		type name, T.Name
		type @tipe, Expression if @tipe?
		type @lazy, Boolean
		@name = name.text
		{ @pos } = name

	toString: ->
		"<#{@name}:#{@pos}>"

	compile: ->
		mangle @name

	typeCheck: (fileName, indent) ->
		if @tipe?
			tipe =
				@tipe.toNode fileName, indent
			nameLit =
				new Literal new T.StringLiteral @pos, @name
			name =
				nameLit.toNode fileName, indent
			[ tipe, '.check(', name, ', ', @compile(), ');\n', indent ]
		else
			''

	toMeta: (fileName, indent) ->
		tipe =
			if @tipe?
				[ ", ", (@tipe.toNode fileName, indent) ]
			else
				''

		@nodeWrap [ "_arg('", @name, "'", tipe, ')' ], fileName

	@it = (pos) ->
		@eager new T.Name pos, 'it', 'x'

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
		type @content, Expression
		{ @pos } = @content

	toString: ->
		"(#{@content})"

	compile: (fileName, indent) ->
		@content.compile fileName, indent

jsLiteral = (pos, text) ->
	new Literal new T.JavascriptLiteral pos, text, 'special'

class ManyArgs extends Expression
	constructor: (@value) ->
		type @value, Expression
		@pos = @value.pos

	toString: ->
		"...#{@value}"

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
	trait: trait
	jsLiteral: jsLiteral
	ManyArgs: ManyArgs
