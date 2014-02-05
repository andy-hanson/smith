{ check, type, typeExist } =  require '../help/✔'
{ countWhere, interleave, interleavePlus, isEmpty } = require '../help/list'
{ endsWith } = require '../help/str'
Pos = require '../compile-help/Pos'
Block = require './Block'
DefLocal = require './DefLocal'
Expression = require './Expression'
Meta = require './Meta'
Literal = require './Literal'
Local = require './Local'

###
Represents a function.
###
module.exports = class FunDef extends Expression
	###
	Everything but `pos` and `args` may be `null`.
	@param meta
	  Meta-info associated with this function.
	@param tipe
	  Return type.
	@param args [Array<Local>]
	  Arguments to the function.
	  Considered optional if they end in a ~.
	@param restArg
	  Argument to get rest of inputs to the function (past @args).
	@param body
	  Function contents.
	###
	constructor: (@pos, @meta, @tipe, @args, @restArg, @body) ->
		check arguments.length == 6
		type @pos, Pos, @args, Array
		typeExist @body, Block, @meta, Meta,
			@tipe, Expression, @restArg, Local,
			@body, Block

	###
	Whether `arg` is optional (looks like `~arg`).
	@private
	###
	_isOption: (arg) ->
		type arg, Local
		endsWith arg.name, '~'

	###
	Assigns arguments when there are no option arguments.
	###
	_optLessAssignArgs: (context) ->
		out = [ ]

		if context.options().checks()
			checks =
				@args.map (arg) ->
					arg.typeCheck context
				.filter (x) ->
					x != null
			out = checks

		if @restArg?
			getRest =
				Literal.JS @pos,
					"global.Array.prototype.slice.call(arguments, #{@args.length});"
			defRest =
				new DefLocal @restArg, getRest
			out.push defRest.toNode context

		if isEmpty out
			null
		else
			interleavePlus out, "\n#{context.indent()}"

	###
	Assigns arguments when there are options (more complicated than optLess!)
	###
	_optFullAssignArgs: (context, nOpts) ->
		if @restArg?
			cFail @pos, "Can not have both optional and rest arguments"

		nNormal =
			@args.length - nOpts

		# What number *option* we're on. In `a b~ c d~`, `d~` is option 2.
		optIndex = 0

		assigns =
			@args.map (arg) =>
				inside =
					arg.typeCheckValue context, (Literal.JS arg.pos, '_r[_i++]')

				assigned =
					if @_isOption arg
						nth = optIndex + nNormal
						optIndex += 1
						[ '(_l > ', "#{nth}", ') ? _p.Some.of(', inside, ') : _p.None' ]
					else
						inside
				[ (arg.toNode context), ' = ', assigned ]

		assigns.unshift '_i = 0', '_r = arguments', '_l = _r.length'

		commadAssigns =
			interleave assigns, ",\n\t#{context.indent()}"

		[ 'var ', commadAssigns, ';\n', context.indent() ]

	###
	If necessary, does argument assignments and checks.
	###
	assignArgs: (context) ->
		nOpts =
			countWhere @args, (arg) =>
				@_isOption arg

		if nOpts == 0
			@_optLessAssignArgs context
		else
			@_optFullAssignArgs context, nOpts

	# @noDoc
	compile: (context) ->
		maybeMeta = (kind) =>
			if @meta?[kind]?
				[ (@meta[kind].toNode context), '\n', context.indent() ]
			else
				null
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
				if needRes
					"\tvar res = null;"
				else
					null
		outCond =
			maybeMeta 'out'
		typeCheck =
			if context.options().checks()
				loc =
					Local.res @pos, @tipe
				loc.typeCheck context.indented()
			else
				null
		meta =
			if @meta?
				@meta.make @, context
			else
				''
		res =
			if needRes
				'return res;'
			else
				null

		maybe = (x) ->
			if x == null
				''
			else
				check x != '', 'AUGH' # TODO: remove
				[ '\n\t', context.indent(), x ]

		[ '_f(this, function(', argNames, ') {',
			(maybe assignArgs),
			(maybe inCond),
			(maybe body),
			(maybe typeCheck),
			(maybe outCond),
			(maybe res),
			'\n', context.indent(),
			'}', meta, ')' ]


	###
	Function with just meta, args, and body. (No return type or rest parameter).
	###
	@plain: (pos, meta, args, body) ->
		new FunDef pos, meta, null, args,  null, body

	###
	Just the body, no meta, no args
	###
	@body: (body) ->
		@plain body.pos, null, [ ], body
