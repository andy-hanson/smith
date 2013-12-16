Function.prototype.unbound = ->
	if @_unbound?
		@_unbound._meta = @_meta
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

def = (name, method) ->
	this._proto[name] = this._methods[name] = method.unbound()

makeAnyClass = (name, maybeIs, maybeProto, maybeConstructor) ->
	unless (Object name) instanceof String
		throw new Error "name is not a String; is #{name}"

	superClass = superMetaClass = metaClass = clazz = null

	isAny =
		maybeProto == Object.prototype

	if isAny
		# superClass is null
		# not super-meta, but Any-Class is Any.
		superMetaClass = null
		# Any-Class is a Any-Class.
		metaClassProto = Object.create Object.prototype
		metaClass = Object.create metaClassProto
		metaClass._proto = metaClassProto
		metaClass._is = metaClass
		# metaClass._proto is made when constructing AnyClass
	else
		superClass =
			maybeIs ? Any
		superMetaClass = superClass.class()

		metaClass = Object.create superMetaClass._proto
		metaClass._proto = Object.create superMetaClass._proto

		metaClass._is = superMetaClass

	clazz = Object.create metaClass._proto

	clazz._proto =
		maybeProto ? Object.create superClass._proto

	metaClass._name = "#{name}-Class"
	clazz._name = name

	clazz._is = superClass

	metaClass._id = nextClassID
	clazz._id = nextClassID + 1
	nextClassID += 2

	metaClass._methods = { }
	clazz._methods = { }

	(Object.getOwnPropertyNames clazz._proto).forEach (name) ->
		value = clazz._proto[name]
		if value instanceof Function
			clazz._methods[name] = value

	def.call metaClass, 'class', -> metaClass
	metaClass._proto["__is-a-id-#{metaClass._id}"] = yes

	def.call clazz, 'class', -> clazz
	clazz._proto["__is-a-id-#{clazz._id}"] = yes

	if maybeConstructor? and not isAny
		def.call clazz, 'construct', ->
			maybeConstructor.apply @, arguments

	allClasses.push metaClass
	allClasses.push clazz

	clazz

#AnyClassProto = { }

#AnyClass = { _proto: AnyClassProto }

#Any = Object['to-class'] 'Any'

#AnyClass = makeAnyClass 'Any-Class', Any, AnyClassProto

Any = Object['to-class'] 'Any'

AnyClass = Any.class()

def.call AnyClass, '-def', def

AnyClass['-def'] 'construct', makeAnyClass

###
AnyClass's of is special
###
AnyClass.of = (name, maybeIs) ->
	if @['_is_meta']
		throw up

	makeAnyClass name, maybeIs

###
Instances of AnyClass (except AnyClass itself) are not as special.
###
AnyClass['-def'] 'of', ->
	obj = Object.create @_proto
	@_proto.construct.apply obj, Array.prototype.slice.call arguments
	obj

Meta =
	AnyClass.of 'Meta'

Meta['-def'] 'construct', (meta) ->
	if meta?
		Object.keys(meta).forEach (name) =>
			unless meta[name]?
				throw new Error '?'
			@[name] = meta[name]



bind = (object, name) ->
	fun = object[name]

	if fun instanceof Function
		x.unbound().bind object
	else
		if fun?
			throw new Error "Member #{name} of #{object} is not a Fun."
		else
			throw new Error "Object #{object} has no method #{name}."

clazz = (name, maybeIs, fun) ->
	tipe =
		AnyClass.of name, maybeIs

	fun.unbound().call tipe

	tipe.__exported ? tipe

string = ->
	Array.prototype.join.call arguments, ''

fun = (delegate, unbound, meta) ->
	f =
		unbound.bind delegate
	f._unbound =
		unbound
	f._meta =
		Meta.of meta
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
	(it) ->
		it[name].apply it, Array.prototype.slice.call arguments, 1

module.exports =
	fun: fun
	bind: bind
	itMethod: itMethod
	string: string
	class: clazz
	lazy: lazy
	Any: Any
	'Any-Class': AnyClass #TODO: not needed, use Any.class()
	Meta: Meta
	'all-classes': ->
		allClasses

