{ type } = require '../help/✔'
Pos = require './Pos'

###
If `condition` is false, `cFail`s.
@param condition [Boolean]
  Should be true. If not, the user made a mistake.
@param message [Function, String]
  Description of what went wrong,
  or a Function returning that.
###
@cCheck = (condition, pos, message) ->
	type condition, Boolean, pos, Pos

	unless condition
		if message instanceof Function
			message = message()
		exports.cFail pos, message

###
Throws an error due to bad code.
Annotates the error with source position.
(It is later annotated with the file name; see compile/directory.coffee).
These _should_ be the user's fault.
@param pos [Pos]
  Location of bad code.
@param message [String]
  Description of what went wrong.
###
@cFail = (pos, message) ->
	type pos, Pos, message, String

	throw new Error "#{pos}: #{message}"
