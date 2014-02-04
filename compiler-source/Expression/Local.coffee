{ type, typeExist } =  require '../help/✔'
Expression = require './Expression'
T = require '../Token'
mangle = require '../help/mangle'
Literal = require './Literal'

module.exports = class Local extends Expression
	constructor: (name, @tipe, @lazy) ->
		type name, T.Name, @lazy, Boolean
		typeExist @tipe, Expression

		@name = name.text
		{ @pos } = name
		@_everUsed = no

	isUsed: ->
		@_everUsed = yes

	everUsed: ->
		@_everUsed

	toString: ->
		"<#{@name}:#{@pos}>"

	compile: ->
		mangle @name

	typeCheck: (context) ->
		if @tipe?
			[ (@typeCheckValue context, @), ';' ]
		else
			''

	typeCheckValue: (context, checked) ->
		type checked, Expression

		if @tipe?
			tipe =
				@tipe.toNode context
			nameLit =
				new Literal new T.StringLiteral @pos, @name
			name =
				nameLit.toNode context
			checkedNode =
				checked.toNode context
			[ tipe, '.check(', name, ', ', checkedNode, ')' ]
		else
			checked.toNode context

	toMeta: (context) ->
		tipe =
			if @tipe?
				[ ", ", (@tipe.toNode context) ]
			else
				''

		@nodeWrap [ "_a('", @name, "'", tipe, ')' ], context

	@it = (pos) ->
		@eager new T.Name pos, 'it', 'x'

	@eager = (name, tipe) ->
		new Local name, tipe, no

	@res = (pos, tipe) =>
		@eager (new T.Name pos, 'res', 'x'), tipe
