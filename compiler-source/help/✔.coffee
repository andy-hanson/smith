typeIt = (args, mustExist) ->
	i = 0
	while i < args.length
		[ value, type ] = #args[i..i+1]
			[ args[i], args[i + 1] ]
		i += 2
		unless value?
			if mustExist
				module.exports.fail "Does not exist of type #{type.name}"
			else
				continue
		unless (Object value) instanceof type
			module.exports.fail \
				"Expected #{value} (a #{value.constructor.name}) " +
				"to be a #{type.name}"



module.exports =
	check: (cond, err) ->
		unless cond
			module.exports.fail err ? 'Check failed'

	fail: (err) ->
		if err instanceof Function
			err = err()
		throw (if err instanceof Error then err else new Error err)

	type: ->
		typeIt arguments, yes

	typeExist: ->
		typeIt arguments, no