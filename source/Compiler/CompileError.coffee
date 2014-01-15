cCheck = (condition, pos, genMessage) ->
	unless condition
		genMessage = (-> @).call genMessage
		message =
			if genMessage instanceof String
				genMessage
			else
				genMessage()
		cFail pos, message

cFail = (pos, message) ->
	throw new Error "#{pos}: #{message}"

module.exports =
	cFail: cFail
	cCheck: cCheck

