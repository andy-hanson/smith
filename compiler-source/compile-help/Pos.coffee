{ type } = require '../help/✔'
{ read } = require '../help/meta'

###
Represents a source position.
1-indexed, as required by source maps.
Immutable, so safe to store in `Expression`s.
###
module.exports = class Pos
	# A simple line, column pair.
	constructor: (@_line, @_column) ->
		type @_line, Number, @_column, Number
		Object.freeze @

	read @, 'line', 'column'

	# @return [Pos] One line down and at column 1.
	plusLine: ->
		new Pos @line() + 1, 1

	# @return [Pos] One column to the right.
	plusColumn: ->
		new Pos @line(), @column() + 1

	# @return [Pos] One line up and at column 1.
	minusLine: ->
		new Pos @line() - 1, 1

	# @return [Pos] One column to the left.
	minusColumn: ->
		new Pos @line(), @column() - 1

	# Shows up in errors.
	toString: ->
		"#{@line()}:#{@column()}"

	# `Pos` representing the start of a file.
	@start: ->
		new Pos 1, 1
