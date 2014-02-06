T = require '../Token'
Stream = require './Stream'
GroupPre = require './GroupPre'
lexQuote = require './lexQuote'
{ cFail, cCheck } = require '../compile-help/✔'
keywords = require '../compile-help/keywords'
{ char } = require '../compile-help/language'
{ check, type, typeEach, typeExist } = require '../help/✔'
{ isEmpty, last, pushAll, repeat } = require '../help/list'
{ endsWith, startsWith, withoutEnd } = require '../help/str'


###
Gets `Token`s out of a `Stream`.
@param inQuoteInterpolation [Boolean]
  Whether this is inside of a quote interpolation.
  If so, } causes this method to finish.
@return [Array<Token>]
  Also, `stream` is moved along.
###
module.exports = tokenize = (stream, inQuoteInterpolation = no) ->
	type stream, Stream
	type inQuoteInterpolation, Boolean

	removePrecedingNL = ->
		if T.nl last out
			# No \n precedes '|' or '.x'
			out.pop()

	# returns String
	takeName = ->
		cCheck not (char.digit.test stream.peek()), stream.pos(),
			'Expected name, got number'
		name = stream.takeWhile char.name
		cCheck not (isEmpty name), stream.pos(),
			'Expected name, got nothing'
		name

	out = [ ]

	indent = 0

	while ch = stream.peek()
		pos = stream.pos()

		if inQuoteInterpolation and ch == '}'
			stream.readChar()
			return out

		match = (regex) ->
			regex.test ch
		maybeTake = (regex) ->
			stream.maybeTake regex

		token =
			switch
				when (match char.reserved)
					cFail pos, "Reserved character '#{ch}'"

				when (match char.digit) or (ch == '-' and char.digit.test stream.peek 1)
					first = stream.readChar()
					num = stream.takeWhile char.number
					# Allow 0.5.cos
					if endsWith num, '.'
						stream.stepBack()
						num = withoutEnd num, '.'
					new T.NumberLiteral pos, "#{first}#{num}"

				when maybeTake char.groupPre
					new GroupPre stream.pos(), ch

				when maybeTake char.precedesName
					kind =
						if ch == '.' and stream.maybeTake /\./ #stream.maybeTake2More '.'
							cCheck stream.readChar() == '.', stream.pos(),
								"Must have 1 '.' or 3, never 2"
							'...x'
						else
							"#{ch}x"

					name = takeName()

					if ch == '.' and stream.peek() == '_'
						stream.readChar()
						check kind == '.x', 'Unexpected _'
						kind = '.x_'

					removePrecedingNL() if ch in [ '@', '.' ]
					if ch == "'"
						new T.StringLiteral pos, name
					else
						new T.Name pos, name, kind

				when match char.name
					name = takeName()
					if stream.maybeTake /_/
						new T.Name pos, name, 'x_'
					else if name in keywords.metaText
						lexQuote name, stream, indent
					else if name in keywords.metaFun
						new GroupPre pos, name
					else if name in keywords.useLike
						stream.takeWhile char.space
						used = stream.takeWhile char.used
						new T.Use pos, used, name
					else if name in keywords.special
						new T.Special pos, name
					else if startsWith name, '$'
						stream.takeWhile char.space
						name2 = takeName()
						new T.Def pos, name, name2
					else
						new T.Name pos, name, 'x'

				when maybeTake /\|/
					removePrecedingNL()
					new GroupPre pos, ch

				when ch == ' '
					stream.takeWhile char.space
					[ ]

				when ch == '\\'
					stream.takeUpTo /\n/
					[ ]

				when ch == '\n'
					cCheck stream.prev() != ' ', pos, 'Line ends in a space.'
					# Skip through blank lines.
					stream.takeWhile /\n/
					old = indent
					now = (stream.takeWhile /\t/).length
					check stream.peek() != ' ', stream.pos(), 'Line begins with a space.'
					indent = now
					if now == old
						removePrecedingNL()
						new T.Special pos, '\n'
					else if now < old
						x = repeat (old - now), new GroupPre stream.pos(), '←'
						x.push new T.Special stream.pos(), '\n'
						x
					else if now == old + 1
						new GroupPre stream.pos(), '→'
					else
						cFail stream.pos(), 'Line is indented more than once.'

				when maybeTake /[`"]/
					lexQuote ch, stream, indent

				else
					cFail pos, "Do not recognize char '#{ch}'"

		if token instanceof Array
			out.push token...
		else
			out.push token

	out

