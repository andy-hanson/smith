Pos = require './Pos'

module.exports = class Stream
	constructor: (@str) ->
		@idx = 0
		@pos = Pos.start

	hasMore: ->
		@idx < @str.length

	prev: ->
		@str[@idx - 1]

	peek: ->
		@str[@idx]

	readChar: ->
		x = @peek()
		if x == '\n'
			@pos = @pos.plus_line()
		else
			@pos = @pos.plus_column()
		@idx += 1
		x

	takeWhile: (cond) ->
		old_idx = @idx
		while @peek() and cond @peek()
			@readChar()
		@str.slice old_idx, @idx

	takeMatching: (rgx) ->
		@takeWhile (x) ->
			x.match rgx

	takeNotMatching: (rgx) ->
		@takeWhile (x) ->
			not x.match rgx

	takeUpToString: (subStr) ->

		start = @idx
		x = @str.indexOf subStr, start
		end =
			if x == -1
				@str.length
			else
				x

		(end - start).times =>
			@readChar()

		@str.slice start, @pos
