{ type, typeExist } =  require '../help/✔'
{ interleave, rightUnCons } = require '../help/list'
{ cCheck } = require '../compile-help/✔'
T = require '../Token'
Pos = require '../compile-help/Pos'
{ isEmpty } = require '../help/list'
DefLocal = require './DefLocal'
Expression = require './Expression'
Literal = require './Literal'
AccessLocal = require './AccessLocal'
Null = require './Null'

###
A bunch of statements in a row.
Usually, the last one is returned.
###
module.exports = class Block extends Expression
	###
	@param subs [Array]
	  The lines of the block.
	  Usually, the last one is returned.
	###
	constructor: (@pos, @subs) ->
		type @pos, Pos, @subs, Array
		# fix up @subs so `null` can be returned.
		if isEmpty @subs
			@subs.push new Null @pos

	###
	Wrap this block in `function() { ...block... }()`
		so it can be treated as a single value.
	(Wrapping may not be necessary.
		In that case just returns the only sub-Expression.)
	@return [SourceNode]
	###
	toValue: (context) ->
		if @subs.length == 1 and not (@subs[0] instanceof DefLocal)
			@subs[0].toNode context
		else
			x =
				[ '_f(this, function() {\n\t',
					context.indent(),
					(@toNode context.indented()),
					'\n', context.indent(), '})()' ]
			@nodeWrap x, context

	###
	Results of compiling each sub-Expression.
	Throws out those compiling to the empty string.
	@private
	@return [Array<Chunk>]
	###
	_compiledSubs: (subs, context) ->
		out = [ ]
		subs.forEach (sub) ->
			compiled =
				sub.compile context
			if compiled != ''
				out.push sub.nodeWrap compiled, context
		out

	###
	Usual compile;  the last expression is returned.
	###
	compile: (context) ->
		@_compileWithLast context, (x) ->
			[ 'return ', x, ';' ]

	###
	The last expression is assigned to a new local 'res'.
	###
	toMakeRes: (context) ->
		x =
			@_compileWithLast context, (x) ->
				[ 'var res = ', x, ';' ]

		@nodeWrap x, context

	###
	Compiled body, with `doIfNotSpecial` done on the last expression.
	@private
	###
	_compileWithLast: (context, doIfNotSpecial) ->
		[ allButLast, last ] =
			rightUnCons @subs

		node =
			last.toNode context

		lastNode =
			if last instanceof Literal and T.indentedJS last.literal
				node
			else if last instanceof DefLocal
				access =
					new AccessLocal @pos, last.local
				accessNode =
					doIfNotSpecial access.toNode context
				[ node, ';\n', context.indent(), accessNode ]
			else
				[ doIfNotSpecial node, ';' ]

		compiled =
			@_compiledSubs allButLast, context
		compiled.push lastNode

		interleave compiled, ";\n#{context.indent()}"
