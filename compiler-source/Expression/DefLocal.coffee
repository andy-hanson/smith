{ type } =  require '../help/✔'
Expression = require './Expression'
Local = require './Local'

###
Looks like:

	∙ local
	  value

(or ∘ local).
Assigns a value to a local variable.
###
module.exports = class DefLocal extends Expression
	###
	Lazy if `local` is.
	@param local [Local]
	@param value [Expression]
	###
	constructor: (@local, @value) ->
		type @local, Local, @value, Expression
		{ @pos } = @local

	###
	If the local is lazy and is never referenced,
		it makes no difference not to compile it.
	@private
	###
	_needsToCompile: ->
		@local.everUsed() or not @local.lazy

	# @noDoc
	compile: (context) ->
		if @_needsToCompile()
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
					[ '_l(this, function() {\n\t\t', context.indent(),
						inner, '\n\t', context.indent(), '})' ]
				else
					@value[if @value instanceof Block then 'toValue' else 'toNode'] context

			typeCheck =
				if context.options().checks() and @local.tipe?
					[ ';\n', context.indent(), @local.typeCheck context ]
				else
					''

			[ 'var ', name, ' =\n\t', context.indent(), val, typeCheck ]
		else
			'' #"/* need not compile local #{@local.name}*/"

	###
	Generates a DefLocal for a `use`.
	This can be done automatically
		since the name of the local is the same as the used thing.
	###
	@fromUse: (use) ->
		new DefLocal use.local, use
