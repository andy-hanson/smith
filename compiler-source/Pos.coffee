module.exports = class Pos
	constructor: (@line, @column) ->
		type @line, Number
		type @column, Number
		Object.freeze @

	plusLine: ->
		new Pos @line + 1, 1

	plusColumn: ->
		new Pos @line, @column + 1

	minusLine: ->
		new Pos @line - 1, 1

	minusColumn: ->
		new Pos @line, @column - 1

	@start =
		new Pos 1, 1

	toString: ->
		"#{@line}:#{@column}"

	inspect: ->
		@toString()
