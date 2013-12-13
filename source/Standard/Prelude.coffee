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

next_type_id = 0

AnyType = null
Any = null

makeAnyType = (name, maybeSuper, maybeProto) ->
	unless (Object name) instanceof String
		throw new Error "name is not a String; is #{name}"

	superType = superMetaType = metaType = null

	if maybeProto == Object.prototype
		superType = null
		superMetaType = null
		metaType = AnyType
		# metaType._proto is made when constructing AnyType
	else
		superType =
			maybeSuperType ? Any
		superMetaType = superType.type()

		metaType = Object.create superMetaType._proto
		metaType._proto = Object.create superMetaType._proto

	type = Object.create metaType._proto

	metaType._name = "#{name}-Type"
	type._name = name

	metaType._super = superMetaType
	type._super = superType

	metaType._id = next_type_id
	type._id = next_type_id + 1
	next_type_id += 2

	type._proto =
		maybeProto ? Object.create superType._proto

	metaType._super = superMetaType
	type._super = superType

	metaType._proto.type = -> metaType
	metaType._proto["__is-a-id-#{metaType._id}"] = yes

	type._proto.type = -> type
	type._proto["__is-a-id-#{type._id}"] = yes

	type

anyTypeProto = { }

AnyType = { _proto: anyTypeProto }
#fake_super =
	# Takes the role of Any before it exists.
#	{ type: -> AnyType }

Any = Object['to-type'] 'Any', null

AnyType = makeAnyType 'Any-Type', null, anyTypeProto

AnyType._proto['‣'] = (name, method) ->
	@_proto[name] = method.unbound()

AnyType['‣'] 'construct', makeAnyType

###
AnyType's of is special
###
AnyType.of = (name, maybeSuperType) ->
	if @['_is_meta']
		throw up

	makeAnyType name, maybeSuperType

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
		{ @_doc, @_in, @_out, @_eg, @_how } = meta


bind = (object, name) ->
	fun = object[name]

	if fun instanceof Function
		x.unbound().bind object
	else
		if fun?
			throw new Error "Member #{name} of #{object} is not a Fun."
		else
			throw new Error "Object #{object} has no method #{name}."

type = (name, maybeSuperType, fun) ->
	tipe =
		AnyType.of name, maybeSuperType

	fun.call tipe

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

module.exports =
	fun: fun
	bind: bind
	string: string
	type: type
	lazy: lazy
	Any: Any
	'Any-Type': AnyType
	Meta: Meta

