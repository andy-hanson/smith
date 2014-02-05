###
Maps names to values.
###
module.exports = class StringMap
	###
	@param obj [Object?]
	  Can construct a StringMap from object literal.
	  Else defaults to empty map.
	###
	constructor: (obj) ->
		@_data =
			if obj?
				obj
			else
				{ }

	###
	Whether the name is a key.
	###
	has: (name) ->
		Object.prototype.hasOwnProperty.call @_data, name

	###
	Retrieves the value at `name`.
	###
	get: (name) ->
		if @has name
			@_data[name]
		else
			throw new Error "No entry #{name}"

	###
	`get` or null.
	###
	maybeGet: (name) ->
		if @has name
			@_data[name]
		else
			null

	###
	Assign `value` to `name`.
	###
	add: (name, value) ->
		@_data[name] = value

	###
	Remove the value at `name`.
	###
	delete: (name) ->
		delete @_data[name]
