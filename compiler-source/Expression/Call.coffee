{ check, type } =  require '../help/✔'
{ containsWhere, interleave } = require '../help/list'
T = require '../Token'
Expression = require './Expression'
ManyArgs = require './ManyArgs'
Me = require './Me'

module.exports = class Call extends Expression
	constructor: (@subject, @verb, @args) ->
		type @subject, Expression, @verb, T.Name, @args, Array
		check @verb.kind == '.x'
		@args.forEach (arg) ->
			type arg, Expression
		@pos = @verb.pos

	toString: ->
		"#{@subject}.#{@verb.text}(#{@args})"

	compile: (context) ->
		subject =
			@subject.toNode context

		hasMany =
			containsWhere @args, (x) ->
				x instanceof ManyArgs

		if hasMany
			parts =
				@args.map (arg) ->
					if arg instanceof ManyArgs
						[ arg.value.toNode context ]
					else
						[ '[', (arg.toNode context), ']' ]

			args =
				[ '[', (interleave parts, ', '), ']' ]

			[ '_c(', subject, ", '", @verb.text, "', ", args, ')' ]
		else
			parts =
				@args.map (x) ->
					x.toNode context
			args =
				interleave parts, ', '

			[ subject, "['", @verb.text, "'](", args, ')' ]

	@me = (pos, verb, args) ->
		verb = new T.Name pos, verb, '.x'
		new Call (new Me pos), verb, args

	@of = (expr, args) ->
		verb = new T.Name expr.pos, 'of', '.x'
		new Call expr, verb, args

	@noArgs = (subject, verb) ->
		new Call subject, verb, []
