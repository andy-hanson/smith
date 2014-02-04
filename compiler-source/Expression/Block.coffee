{ type, typeExist } =  require '../help/✔'
{ interleave, rightUnCons } = require '../help/list'
{ cCheck } = require '../compile-help/✔'
T = require '../Token'
Pos = require '../compile-help/Pos'
{ isEmpty } = require '../help/list'
DefLocal = require './DefLocal'
Expression = require './Expression'
Literal = require './Literal'
LocalAccess = require './LocalAccess'
Null = require './Null'

module.exports = class Block extends Expression
	constructor: (@pos, @subs) ->
		type @pos, Pos, @subs, Array

		if isEmpty @subs
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
		interleave @filteredSubs(@subs, context), ";\n#{context.indent}"

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
		[ allButLast, last ] =
			rightUnCons @subs

		node =
			last.toNode context

		#cCheck (not (last instanceof DefLocal)), @pos, 'Expression should not end in local'

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
			@filteredSubs allButLast, context
		compiled.push lastNode

		interleave compiled, ";\n#{context.indent}"
