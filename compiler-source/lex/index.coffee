Stream = require './Stream'
tokenize = require './tokenize'
checkSpaces = require './checkSpaces'
{ type } = require '../help/✔'
joinGroups = require './joinGroups'
Options = require '../run/Options'

###
Converts a `String` to `Token`s.
@return [Array<Token>]
###
module.exports = lex = (str, options) ->
	type str, String, options, Options

	checkSpaces str, options
	str += '\n'

	stream =
		new Stream str
	preTokens =
		tokenize stream
	joinGroups preTokens
