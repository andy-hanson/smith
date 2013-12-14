Function.prototype.unbound = ->
	if @_unbound?
		@_unbound._meta = @_meta
		@_unbound
	else
		@

Function.prototype['to-type'] = (name, maybeSuper) ->
	name ?= @name
	@['_to-type'] ?=
		makeAnyType name, maybeSuper, @prototype
	@['_to-type']

nextTypeID = 0

AnyType = null
Any = null

makeAnyType = (name, maybeIs, maybeProto) ->
	unless (Object name) instanceof String
		throw new Error "name is not a String; is #{name}"

	superType = superMetaType = metaType = null

	if maybeProto == Object.prototype
		#superType = null
		#superMetaType = null
		metaType = AnyType
		# metaType._proto is made when constructing AnyType
	else
		superType =
			maybeIs ? Any
		superMetaType = superType.type()

		metaType = Object.create superMetaType._proto
		metaType._proto = Object.create superMetaType._proto

	type = Object.create metaType._proto

	metaType._name = "#{name}-Type"
	type._name = name

	metaType._is = superMetaType
	type._is = superType

	metaType._id = nextTypeID
	type._id = nextTypeID + 1
	nextTypeID += 2

	type._proto =
		maybeProto ? Object.create superType._proto

	metaType._methods = { }
	type._methods = { }

	(Object.getOwnPropertyNames type._proto).forEach (name) ->
		value = type._proto[name]
		if value instanceof Function
			type._methods[name] = value

	metaType._proto.type = -> metaType
	metaType._proto["__is-a-id-#{metaType._id}"] = yes

	type._proto.type = -> type
	type._proto["__is-a-id-#{type._id}"] = yes

	type

anyTypeProto = { }

AnyType = { _proto: anyTypeProto }

Any = Object['to-type'] 'Any'

AnyType = makeAnyType 'Any-Type', Any, anyTypeProto

AnyType._proto['‣'] = (name, method) ->
	@_proto[name] = @_methods[name ] = method.unbound()

AnyType['‣'] 'construct', makeAnyType


###
AnyType's of is special
###
AnyType.of = (name, maybeIs) ->
	if @['_is_meta']
		throw up

	makeAnyType name, maybeIs

###
Instances of AnyType (except AnyType itself) are not as special.
###
AnyType['‣'] 'of', ->
	obj = Object.create @_proto
	@_proto.construct.apply obj, Array.prototype.slice.call arguments
	obj

Meta =
	AnyType.of 'Meta'

Meta['‣'] 'construct', (meta) ->
	if meta?
		for name, value of meta
			@[name] = value



bind = (object, name) ->
	fun = object[name]

	if fun instanceof Function
		x.unbound().bind object
	else
		if fun?
			throw new Error "Member #{name} of #{object} is not a Fun."
		else
			throw new Error "Object #{object} has no method #{name}."

type = (name, maybeIs, fun) ->
	tipe =
		AnyType.of name, maybeIs

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
	type: type
	lazy: lazy
	Any: Any
	'Any-Type': AnyType
	Meta: Meta

