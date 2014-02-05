# @noDoc
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

###
Fail because this method is abstract and wasn't implemented.
###
@abstract = ->
	fail 'Not implemented'

###
Assert the condition.
@param err [String, Error, Function]
	Input to `fail` or a `Function` producing it.
###
@check = (cond, err) ->
	unless cond
		if err instanceof Function
			err = err()
		module.exports.fail err ? 'Check failed'

###
If `err` is an Error, throws it.
Else, throws a new Error with `err` as the message.
###
@fail = (err) ->
	throw (if err instanceof Error then err else new Error err)

###
Checks that each odd argument is an instance of each even argument.
@example
  type 1, Number, 'one', String
###
@type = ->
	typeIt arguments, yes

###
Checks that every member of `array` is of type `elementType`.
###
@typeEach = (array, elementType) ->
	exports.type array, Array
	array.forEach (element) ->
		exports.type element, elementType

###
Like `type` but non-existent arguments are OK.
@example
  typeExist null, Number
###
@typeExist = ->
	typeIt arguments, no