{ type } = require './✔'

###
Generates a reader for each name in `names`.
The property must be named `_name`.
###
@read = (clazz, names...) ->
	type clazz, Function
	names.forEach (name) ->
		type name, String
		clazz.prototype[name] = ->
			@["_#{name}"]
