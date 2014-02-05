Pos = require '../compile-help/Pos'
{ cCheck } = require '../compile-help/✔'
{ check, type } = require '../help/✔'
{ times } = require '../help/oth'

###
Pretends that a string is streaming.
###
module.exports = class Stream
	###
	@param str [String]
	  Full text (this is not a real stream).
	###
	constructor: (@str) ->
		@index = 0
		@pos = Pos.start()

	###
	If the next character is in `charClass`, read it.
	###
	maybeTake: (charClass) ->
		type charClass, RegExp
		@readChar() if charClass.test @peek()

	###
	The next (or skip-th next) character without modifying the stream.
	###
	peek: (skip = 0) ->
		@str[@index + skip]

	###
	The character before `peek()`.
	###
	prev: ->
		@peek -1

	###
	Takes the next character (modifying the stream).
	###
	readChar: ->
		x = @peek()
		if x == '\n'
			@pos = @pos.plusLine()
		else
			@pos = @pos.plusColumn()
		@index += 1
		x

	###
	Goes back `n` characters.
	(If it goes back a line, column info is destroyed,
		but that's OK since \n doesn't become an Expression.)
	###
	stepBack: (n = 1) ->
		times n, =>
			@index -= 1
			if @peek() == '\n'
				@pos = @pos.minusLine()
			else
				@pos = @pos.minusColumn()

	###
	Reads as long as characters satisfy `condition`.
	@param condition [Function, RegExp]
	@return [String]
	###
	takeWhile: (condition) ->
		if condition instanceof RegExp
			charClass = condition
			condition = (char) ->
				charClass.test char

		start = @index
		while @peek() and condition @peek()
			@readChar()
		@str.slice start, @index

	###
	Reads until a character is in `charClass`.
	###
	takeUpTo: (charClass) ->
		type charClass, RegExp
		@takeWhile (char) ->
			not charClass.test char