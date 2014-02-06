{ check, type } =  require '../help/✔'
{ interleave } = require '../help/list'
keywords = require '../compile-help/keywords'
Pos = require '../compile-help/Pos'
Expression = require './Expression'
Local = require './Local'

###
The meta of a `Fun`.
###
module.exports = class Meta extends Expression
	###
	Starts with only @pos, but new members are added named _in, _out, etc.
	###
	constructor: (@pos) ->
		type @pos, Pos

	###
	I must be the meta of `fun`.
	Returns `_make-meta-pre`, a closure that, when called,
	returns a structure that can be converted to an instance of Smith's Meta.
	@return [Chunk]
	###
	make: (fun, context) ->
		Fun = require './Fun'
		type fun, Fun
		check fun.meta == @

		parts = [ ]

		keywords.allMeta.forEach (name) =>
			if context.options().meta() or name == '_arguments'
				val =
					@[name]
				if val?
					part =
						if name in keywords.metaFun
							x = (Fun.body val).toNode context.indented()
						else
							val.toNode context

					parts.push [ "'_", name, "': ", part ]

		arg = (x) ->
			type x, Local
			x.toMeta context
		args = (x) ->
			interleave (x.map arg), ', '
		rest = (name, x) ->
			if fun[x]?
				parts.push [ "'_#{name}': ", arg fun[x] ]

		if fun.optArgs?
			parts.push [ '_options: [', (args fun.optArgs), ']' ]
		rest 'rest-option', 'optRest'
		parts.push [ '_arguments: [', (args fun.args), ']' ]
		rest 'rest-argument', 'maybeRest'

		body =
			interleave parts, ",\n\t#{context.indent()}"

		x = [ ', _f(this, function() { return {\n\t',
			context.indent(), body, '\n',
			context.indent(), '}; })' ]

		@nodeWrap x, context
