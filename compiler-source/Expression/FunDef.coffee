{ check, type, typeExist } =  require '../help/✔'
{ countWhere, interleave, interleavePlus } = require '../help/list'
{ endsWith } = require '../help/str'
Pos = require '../compile-help/Pos'
Block = require './Block'
DefLocal = require './DefLocal'
Expression = require './Expression'
Meta = require './Meta'
Literal = require './Literal'
Local = require './Local'

module.exports = class FunDef extends Expression
	constructor: (@pos, @meta, @tipe, @args, @maybeRest, @body) ->
		check arguments.length == 6
		type @pos, Pos, @args, Array
		typeExist @body, Block, @meta, Meta,
			@tipe, Expression, @maybeRest, Local,
			@body, Block

	toString: ->
		"{#{@args} ->\n #{@body?.toString().indent()}}"

	isOpts: (arg) ->
		type arg, Local
		endsWith arg.name, '~'

	optLessAssignArgs: (context) ->
		getRest = (rest, argsRendered, nArgs, end) =>
			if rest?
				get =
					Literal.JS @pos,
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

		[ (interleavePlus checks, "\n#{context.indent}"), rest ]

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
		assigns = interleave assigns, x

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
			interleave (@args.map (arg) -> arg.toNode context.indented()), ', '
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
