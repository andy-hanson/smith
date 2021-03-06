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
def = (name, method, overridable = yes) ->
	unbound = method.unbound()
	unbound._class = this
	imm @_methods, name, unbound

	assign =
		if overridable
			(object, name, value) ->
				object[name] = value
		else
			imm

	assign @_proto, name, unbound

	defInherit = (inheritor) ->
		assign inheritor._proto, name = unbound
		inheritor['_trait-of'].forEach defInherit

	# only traits need this manual inheritence
	@['_trait-of'].forEach defInherit

imm = (object, name, value) ->
	global.Object.defineProperty object, name,
		value: value
		enumerable: true

	if object[name] != value
		throw up

makeAnyClass = (name, maybeIs, maybeProto, maybeConstructor) ->
	unless (Object name) instanceof String
		throw new Error "In makeAnyClass: name is not a String; is #{name}"
	if maybeIs?
		unless AnyClass._id == 0
			throw new Error '?'
		unless maybeIs['__is-a-id-0']?
			throw new Error "super of #{name} must be a Any-Class, not #{maybeIs}"

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

	metaClass['_is-meta'] = yes

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

	(Object.getOwnPropertyNames clazz._proto).forEach (methodName) ->
		if methodName != 'constructor'
			value = clazz._proto[methodName]
			if value instanceof Function
				def.call clazz, methodName, value

	imm metaClass, '-id-check', "__is-a-id-#{metaClass._id}"
	imm clazz, '-id-check', "__is-a-id-#{clazz._id}"

	def.call metaClass, 'class', -> metaClass
	imm metaClass._proto, metaClass['-id-check'], yes

	def.call clazz, 'class', -> clazz
	imm clazz._proto, clazz['-id-check'], yes

	if maybeConstructor? and not isAny
		def.call clazz, 'construct', maybeConstructor

	allClasses.push metaClass
	allClasses.push clazz

	clazz

Any = Object['to-class'] 'Any'

AnyClass = Any.class()

def.call AnyClass, '$new-ok', def

Meta =
	makeAnyClass 'Meta'

bind = (object, name) ->
	fun = object[name]

	if fun instanceof Function
		unbound = fun.unbound()
		boundd = unbound.bind object
		boundd['_make-meta-pre'] = unbound['_make-meta-pre']
		boundd._unbound = unbound
		boundd
	else if fun?
		throw new Error "Member #{name} of #{object} is not a Fun."
	else
		throw new Error "Object #{object} has no method #{name}."

clazz = (name, maybeIs, fun) ->
	cls =
		makeAnyClass name, maybeIs
	if fun?
		cls['_make-meta-pre'] = fun['_make-meta-pre']
		fun.unbound().call cls

	cls.__exported ? cls


fun = (delegate, unbound, makeMetaPre) ->
	f =
		unbound.bind delegate
	f._unbound =
		unbound
	if makeMetaPre?
		imm f, '_make-meta-pre', makeMetaPre
	f

lazy = (delegate, make) ->
	cached = undefined
	->
		cached ? (cached = make.call delegate)

call = (subject, verb, argumentses) ->
	# argumentses is an array of arrays

	args = []
	for newArgs in argumentses
		if newArgs instanceof Array
			Array.prototype.push.apply args, newArgs
		else
			throw up
			args['>>!'] newArgs

	method =
		subject[verb] ?
			throw new Error "#{subject} (a #{subject.class()}) has no method #{verb}"

	method.apply subject, args

Argument = makeAnyClass 'Argument'

Opt = makeAnyClass 'Opt'
Some = makeAnyClass 'Some', Opt
Some['$new-ok'] 'construct', (x) ->
	@_value = x
	Object.freeze @

NoneClass = makeAnyClass 'None', Opt
None = Object.create NoneClass._proto

module.exports =
	fun: fun
	bind: bind
	itMethod: (name) ->
		(it) ->
			method = it[name]
			unless method?
				throw new Error "#{it} has no method #{name}"
			method.apply it, Array.prototype.slice.call arguments, 1
	string: ->
		Array.prototype.join.call arguments, ''
	class: clazz
	lazy: lazy
	Any: Any
	Meta: Meta
	'all-classes': -> allClasses
	call: call
	argument: (name, clazz) ->
		Argument.of name, clazz
	Argument: Argument
	Opt: Opt
	Some: Some
	None: None

