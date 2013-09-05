module.exports = class Pos
	constructor: (@line, @column) ->
		Object.freeze @

	plus_line: ->
		new Pos @line + 1, 1

	plus_column: ->
		new Pos @line, @column + 1

	@start =
		new Pos 1, 1

	toString: ->
		"#{@line}:#{@column}"

	inspect: ->
		@toString()
