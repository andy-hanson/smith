{ type } =  require '../help/✔'
Expression = require './Expression'
Local = require './Local'

module.exports = class DefLocal extends Expression
	constructor: (@local, @value) ->
		type @local, Local, @value, Expression
		{ @pos } = @local

	toString: ->
		"<DefLocal #{@local.name} {#{@value.toString()}}>"

	needsToCompile: ->
		@local.everUsed() or not @local.lazy

	compile: (context) ->
		if @needsToCompile()
			Block = require './Block'
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

			typeCheck =
				if context.options.checks() and @local.tipe?
					[ ';\n', context.indent, @local.typeCheck context ]
				else
					''

			[ 'var ', name, ' =\n\t', context.indent, val, typeCheck ]
		else
			'' #"/* need not compile local #{@local.name}*/"

	@fromUse = (use) ->
		new DefLocal use.local, use
