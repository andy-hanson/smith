Pos = require '../Pos'
{ cCheck } = require '../CompileError'

module.exports = class Stream
	constructor: (@str) ->
		@idx = 0
		@pos = Pos.start

	hasMore: ->
		@idx < @str.length

	stepBack: (n = 1) ->
		n.times =>
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

	takeMatching: (rgx) ->
		@takeWhile (x) ->
			x.match rgx

	takeNotMatching: (rgx) ->
		@takeWhile (x) ->
			not x.match rgx

	takeUpToString: (str) ->
		start = @idx
		end = @str.indexOf str, start

		cCheck end != -1, @pos, ->
			"Expected to find #{str} before end of file."

		(end - start).times =>
			@readChar()

		@str.slice start, end

	takeUpToAndIncludingString: (str) ->
		x = @takeUpToString str
		str.length.times =>
			@readChar()
		x


	maybeTake2More: (ch) ->
		isMore = @peek() == ch
		if isMore
			@readChar()
			cCheck @readChar() == ch, @pos, ->
				"Expected #{ch}"
		isMore
