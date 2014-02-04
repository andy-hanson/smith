Stream = require './Stream'
lexPlain = require './lexPlain'
checkSpaces = require './checkSpaces'
{ type } = require '../help/✔'
joinGroups = require './joinGroups'
Options = require '../run/Options'

module.exports = (str, options) ->
	type str, String, options, Options

	checkSpaces str, options
	str += '\n'

	stream =
		new Stream str
	plain =
		lexPlain stream
	tokens =
		joinGroups plain

	tokens
