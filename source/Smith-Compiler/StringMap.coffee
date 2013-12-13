module.exports = class StringMap
	###
	Maps names to values.
	###
	constructor: ->
		@_data = {}

	has: (name) ->
		Object.prototype.hasOwnProperty.call @_data, name

	get: (name) ->
		if @has name
			@_data[name]
		else
			throw new Error "No entry #{name}"

	maybeGet: (name) ->
		if @has name
			@_data[name]
		else
			null

	add: (name, value) ->
		@_data[name] = value
