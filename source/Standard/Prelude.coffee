#unless typeof define == 'function'
#	define = require('amdefine') module

define ->
	Function.prototype.unbound = ->
		if @_unbound?
			@_unbound._meta = @_meta
			@_unbound
		else
			@

	Function.prototype['to-type'] = ->
		@['_to-type'] ?= new constructType @name, @prototype
		@['_to-type']

	next_type_id = 0

	constructType = (name, proto) ->
		if typeof name != 'string'
			throw new Error '?'

		@_id = next_type_id
		next_type_id += 1

		@_name = name

		[ @_super, @_proto ] =
			if proto == Object.prototype
				[ null, proto ]
			else
				[ Object['to-type'](),
					proto ? {} ]

		@_proto.type = =>
			@
		@_proto["__is-a-id-#{@_id}"] = yes
		@_any_defines = no

	constructType.prototype = {}

	Type = new constructType 'Type', constructType.prototype

	Type._proto['‣'] = (name, method) ->
		@_proto[name] = method.unbound()
		@_any_defines = yes

	# TODO: move
	Type['‣'] 'is', (superType) ->
		if Object.keys @_proto > 1
			throw new Error "is must be first, already have #{Object.keys @_proto}"

		@_super = superType['to-type']()

		newProto = Object.create @_super.proto()
		newProto.type = @_proto.type
		@_proto = newProto

	Type['‣'] 'of', ->
		obj = Object.create @_proto
		@_proto.construct.apply obj, Array.prototype.slice.call arguments
		obj

	Type['‣'] 'to-type', ->
		@

	Type['‣'] 'construct', constructType

	Type['‣'] 'export', (exported) ->
		@__exported = exported

	checkExists = (name, a) ->
		unless a?
			throw new Error "#{name} does not exist."

	Type['‣'] 'check', (name, a) ->
		checkExists name, a
		unless @['subsumes?'](a)
			throw new Error "#{name} is not a #{@}; is #{a}"

	bind = (object, name) ->
		fun = object[name]

		if fun instanceof Function
			x.unbound().bind object
		else
			if fun?
				throw new Error "Member #{name} of #{object} is not a Fun."
			else
				throw new Error "Object #{object} has no method #{name}."

	type = (name, fun) ->
		tipe = Type.of name

		fun.call tipe

		tipe.__exported ? tipe

	string = ->
		Array.prototype.join.call arguments, ''

	Meta = Type.of 'Meta'

	Meta['‣'] 'construct', (meta) ->
		if meta?
			{ @_doc, @_in, @_out, @_eg, @_how } = meta

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

	fun: fun
	bind: bind
	string: string
	type: type
	lazy: lazy
	checkExists: checkExists
	Type: Type
	Meta: Meta


