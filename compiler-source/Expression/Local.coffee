{ type, typeExist } =  require '../help/✔'
Expression = require './Expression'
T = require '../Token'
{ mangle } = require '../compile-help/JavaScript-syntax'
Literal = require './Literal'

###
A local variable.
Used by both `AccessLocal` and `DefLocal`
###
module.exports = class Local extends Expression
	###
	@param name [String]
	@param tipe [Expression?]
	@param lazy [Boolean]
	###
	constructor: (name, @tipe, @lazy = no) ->
		type name, T.Name, @lazy, Boolean
		typeExist @tipe, Expression

		@name = name.text
		{ @pos } = name
		@_everUsed = no

	###
	Call this when using the Local.
	###
	isUsed: ->
		@_everUsed = yes

	###
	Whether `isUsed` was ever called.
	###
	everUsed: ->
		@_everUsed

	###
	JavaScript-compatible local name.
	@return [String]
	###
	mangled: ->
		mangle @name

	# @noDoc
	compile: ->
		@mangled()

	###
	If a type check is needed, calls `Type.check(thisLocal)`.
	Null if none needed.
	@return [Chunk, null]
	###
	typeCheck: (context) ->
		if @tipe?
			[ (@typeCheckValue context, @), ';' ]
		else
			null

	###
	Wraps `checked` to be certain it can be assigned to me.
	Even if I have no type, this expression should return `checked`.
	###
	typeCheckValue: (context, checked) ->
		type checked, Expression
		checkedNode =
			checked.toNode context

		if @tipe?
			[ (@tipe.toNode context), ".check('", @name, "', ", checkedNode, ')' ]
		else
			checkedNode

	###
	Compiles the part of `_make-meta-pre` that represents and `Argument`.
	###
	toMeta: (context) ->
		tipe =
			if @tipe?
				[ ", ", (@tipe.toNode context) ]
			else
				''

		@nodeWrap [ "_a('", @name, "'", tipe, ')' ], context

	# Used by Locals._add error message.
	toString: ->
		"#{@name}@#{@pos}"

	###
	A local named 'it'.
	###
	@it: (pos) ->
		new Local new T.Name pos, 'it', 'x'

	###
	A local named 'res'
	###
	@res: (pos, tipe) ->
		new Local (new T.Name pos, 'res', 'x'), tipe
