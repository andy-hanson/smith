Function.prototype.unbound = ->
	if @_unbound?
		if @['_make-meta-pre']?
			@_unbound['_make-meta-pre'] = @['_make-meta-pre']
		@_unbound
	else
		@

Function.prototype['to-class'] = (name, maybeSuper) ->
	name ?= @name
	@['_to-class'] ?=
		makeAnyClass name, maybeSuper, @prototype, @
	@['_to-class']

nextClassID = 0
allClasses = []

Any = null




# call with a class as 'this'
def = (name, method) ->
	unbound = method.unbound()
	imm @_methods, name, unbound

	defInherit = (inheritor) ->
		# not immutable - may be overridden
		inheritor._proto[name] = unbound
		inheritor['_trait-of'].forEach defInherit

	defInherit @


imm = (object, name, value) ->
	global.Object.defineProperty object, name,
		value: value

makeAnyClass = (name, maybeIs, maybeProto, maybeConstructor) ->
	unless (Object name) instanceof String
		throw new Error "In makeAnyClass: name is not a String; is #{name}"

	superClass = metaClass = clazz = null

	isAny =
		maybeProto == Object.prototype

	if isAny
		# superClass is null
		# Any-Class is a Any-Class.
		metaClassProto = { }
		# metaClass is Any-Class
		metaClass = Object.create metaClassProto
		imm metaClass, '_proto', metaClassProto
		#imm metaClass, '_super', metaClass #TODO: Any-Class --super-> Any
	else
		superClass =
			maybeIs ? Any
		superMetaClass = superClass.class()

		metaClass = Object.create superMetaClass._proto
		imm metaClass, '_proto', Object.create superMetaClass._proto

		#imm metaClass, '_super', superMetaClass

	clazz = Object.create metaClass._proto

	imm clazz, '_super', superClass if superClass?
	imm metaClass, '_super',
		if isAny then clazz else superMetaClass

	imm clazz, '_proto',
		maybeProto ? Object.create superClass._proto

	imm metaClass, '_name',
		"#{name}-Class"
	imm clazz, '_name',
		name

	imm metaClass, '_traits', []
	imm clazz, '_traits', []

	imm metaClass, '_super-of', []
	imm clazz, '_super-of', []
	imm metaClass, '_trait-of', []
	imm clazz, '_trait-of', []

	imm clazz, '_inherits-from',
		if clazz.super?
			clazz._super['_inherits-from'].concat clazz._super
		else
			[]
	imm metaClass, '_inherits-from',
		metaClass._super['_inherits-from'].concat metaClass._super

	metaClass._super['_super-of'].push metaClass
	clazz._super['_super-of'].push clazz if clazz._super?

	imm metaClass, '_id', nextClassID
	imm clazz, '_id', nextClassID + 1
	nextClassID += 2

	imm metaClass, '_methods', {}
	imm clazz, '_methods', {}
	imm metaClass, '_static-methods', {}
	imm clazz, '_static-methods', {}

	(Object.getOwnPropertyNames clazz._proto).forEach (name) ->
		value = clazz._proto[name]
		if value instanceof Function
			def .call clazz, name, value#imm clazz._methods, name, value

	def.call metaClass, 'class', -> metaClass
	imm metaClass._proto, "__is-a-id-#{metaClass._id}", yes

	def.call clazz, 'class', -> clazz
	imm clazz._proto, "__is-a-id-#{clazz._id}", yes

	if maybeConstructor? and not isAny
		def.call clazz, 'construct', maybeConstructor

	allClasses.push metaClass
	allClasses.push clazz

	clazz

Any = Object['to-class'] 'Any'

AnyClass = Any.class()

def.call AnyClass, '-def', def

AnyClass['-def'] 'construct', makeAnyClass

AnyClass['-def'] 'of', ->
	if @['_is_meta']
		throw up

	obj =
		Object.create @_proto
	constructor =
		@_proto.construct
	unless constructor instanceof Function
		message =
			if constructor?
				"#{@} has bad constructor #{constructor}"
			else
				"#{@} has no constructor"
		throw new Error message
	constructor.apply obj, Array.prototype.slice.call arguments
	obj

Meta =
	makeAnyClass 'Meta'

Meta['-def'] 'construct', (meta) ->
	(Object.keys meta).forEach (name) =>
		unless meta[name]?
			throw new Error '?'
		imm @, name, meta[name]

bind = (object, name) ->
	fun = object[name]

	if fun instanceof Function
		fun.unbound().bind object
	else if fun?
		throw new Error "Member #{name} of #{object} is not a Fun."
	else
		throw new Error "Object #{object} has no method #{name}."

clazz = (name, maybeIs, fun) ->
	cls =
		makeAnyClass name, maybeIs
	cls['_make-meta-pre'] = fun['_make-meta-pre']

	fun.unbound().call cls

	cls.__exported ? cls

string = ->
	Array.prototype.join.call arguments, ''

fun = (delegate, unbound, makeMetaPre) ->
	f =
		unbound.bind delegate
	f._unbound =
		unbound
	if makeMetaPre?
		imm f, '_make-meta-pre', makeMetaPre
	f

lazy = (delegate, make) ->
	get = ->
		made =
			make.call delegate
		get = ->
			made
		made
	get

itMethod = (name) ->
	unless (Object name) instanceof String
		throw new Error '?'
	(it) ->
		method = it[name]
		unless method?
			throw new Error "#{it} has no method #{name}"
		it[name].apply it, Array.prototype.slice.call arguments, 1

checkNumberOfArguments = (args, expectedNumber) ->
	if args.length < expectedNumber
		throw new global.Error \
			"Expected #{expectedNumber} arguments, only got [" +
			(Array.prototype.join.call args, ', ') + ']'

call = (subject, verb, optionses, argumentses) ->
	# optionses and argumentses are arrays of arrays
	unless (Object verb) instanceof String
		throw new global.Error '?'

	opts = []
	for newOpts in optionses
		Array.prototype.push.apply opts, newOpts

	args = []
	for newArgs in argumentses
		Array.prototype.push.apply args, newArgs

	op = subject[verb]
	unless op?
		throw new Error "#{subject} has no method #{verb}"

	if opts.length == 0
		op.apply subject, args
	else
		args.unshift optionalArgumentTag, opts
		op.apply subject, args

# A unique object to indicate when optinal arguments are passed.
optionalArgumentTag =
	'OPTIONAL-ARGUMENT-TAG'

Argument = makeAnyClass 'Argument'

argument = (name, clazz) ->
	Argument.of name, clazz

Opt = makeAnyClass 'Opt'
Some = makeAnyClass 'Some', Opt
Some['-def'] 'construct', (x) ->
	@_value = x
	Object.freeze @

NoneClass = makeAnyClass 'None', Opt
None = Object.create NoneClass._proto

module.exports =
	fun: fun
	bind: bind
	itMethod: itMethod
	string: string
	class: clazz
	lazy: lazy
	Any: Any
	Meta: Meta
	'all-classes': -> allClasses
	checkNumberOfArguments: checkNumberOfArguments
	optionalArgumentTag: optionalArgumentTag
	call: call
	argument: argument
	Argument: Argument
	Opt: Opt
	Some: Some
	None: None
	#makeAnyClass: makeAnyClass
