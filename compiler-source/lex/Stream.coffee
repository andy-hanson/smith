Pos = require '../compile-help/Pos'
{ cCheck } = require '../compile-help/✔'
{ times } = require '../help/oth'
{ check } = require '../help/✔'

module.exports = class Stream
	constructor: (@str) ->
		@idx = 0
		@pos = Pos.start

	hasMore: ->
		@idx < @str.length

	stepBack: (n = 1) ->
		times n, =>
			@idx -= 1
			if @peek() == '\n'
				@pos = @pos.minusLine()
			else
				@pos = @pos.minusColumn()

	prev: ->
		@str[@idx - 1]

	peek: (skip = 0) ->
		@str[@idx + skip]

	readChar: ->
		x = @peek()
		if x == '\n'
			@pos = @pos.plusLine()
		else
			@pos = @pos.plusColumn()
		@idx += 1
		x

	takeWhile: (cond) ->
		old_idx = @idx
		while @peek() and cond @peek()
			@readChar()
		@str.slice old_idx, @idx

	maybeTake: (ch) ->
		take = @peek() == ch
		@readChar() if take
		take

	takeMatching: (regex) ->
		@takeWhile (x) ->
			regex.test x

	takeNotMatching: (regex) ->
		@takeWhile (x) ->
			not regex.test x

	takeUpToString: (str) ->
		start = @idx
		end = @str.indexOf str, start

		cCheck end != -1, @pos, ->
			"Expected to find #{str} before end of file."

		times (end - start), =>
			@readChar()

		if str.length == 1
			check @peek() == '\n'

		@str.slice start, end

	takeUpToAndIncludingString: (str) ->
		x = @takeUpToString str
		times str.length, =>
			@readChar()
		x


	maybeTake2More: (ch) ->
		isMore = @peek() == ch
		if isMore
			@readChar()
			cCheck @readChar() == ch, @pos, ->
				"Expected #{ch}"
		isMore
