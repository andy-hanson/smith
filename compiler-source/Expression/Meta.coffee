{ type } =  require '../help/✔'
{ interleave } = require '../help/list'
keywords = require '../compile-help/keywords'
Pos = require '../compile-help/Pos'
Expression = require './Expression'
Local = require './Local'

module.exports = class Meta extends Expression
	constructor: (@pos) ->
		type @pos, Pos

	@all =
		[ 'eg', 'sub-eg' ].concat keywords.metaText

	make: (fun, context) ->
		FunDef = require './FunDef'
		parts = []

		Meta.all.forEach (name) =>
			if context.options.meta() or name == '_arguments'
				val =
					@[name]
				if val?
					part =
						if name in keywords.metaFun
							(FunDef.body val).toNode context.indented()
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
			interleave parts, ",\n\t#{context.indent}"

		[ ', function() { return {\n\t', context.indent, body, '\n', context.indent, '}; }' ]


	toString: ->
		"doc: #{@doc}; eg: #{@eg}; how: #{@how}; sub-eg: #{@['sub-eg']}"

