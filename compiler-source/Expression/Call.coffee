{ check, type, typeEach } =  require '../help/✔'
{ containsWhere, interleave } = require '../help/list'
Pos = require '../compile-help/Pos'
T = require '../Token'
Expression = require './Expression'
FunDef = require './FunDef'
Literal = require './Literal'
ManyArgs = require './ManyArgs'
Me = require './Me'

###
Represents a method call.
(Smith has no 'just' function calls, all are methods.)
###
module.exports = class Call extends Expression
	###
	@param subject [Expression]
	@param verb [T.Name]
	@param args [Array<Expression, ManyArgs>]
	###
	constructor: (@subject, @verb, @args) ->
		type @subject, Expression, @verb, T.Name, @args, Array
		check @verb.kind == '.x'
		@pos = @verb.pos

	# @noDoc
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
				@args.map (arg) ->
					arg.toNode context
			args =
				interleave parts, ', '

			[ subject, "['", @verb.text, "'](", args, ')' ]

	###
	Calls a definer.
	###
	@def: (pos, def, fun) ->
		type pos, Pos, def, T.Def, fun, FunDef
		@me pos, def.name, [ (Literal.string pos, def.name2), fun ]

	###
	Looks like `method`.
	A call with `me` as the subject.
	###
	@me: (pos, verb, args) ->
		type pos, Pos, verb, String, args, Array
		verb = new T.Name pos, verb, '.x'
		new Call (new Me pos), verb, args

	###
	Looks like `(a) b`.
	A call with 'of' as the verb.
	###
	@of: (subject, args) ->
		type subject, Expression, args, Array
		verb = new T.Name subject.pos, 'of', '.x'
		new Call subject, verb, args

	###
	Looks like `a.method`
	A call with no arguments.
	###
	@noArgs: (subject, verb) ->
		type subject, Expression, verb, T.Name
		new Call subject, verb, [ ]
