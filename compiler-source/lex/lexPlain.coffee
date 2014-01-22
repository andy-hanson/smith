T = require '../Token'
Stream = require './Stream'
GroupPre = require './GroupPre'
lexQuote = require './lexQuote'
{ cFail, cCheck } = require '../CompileError'
keywords = require '../keywords'

module.exports = (stream, inQuote) ->
	type stream, Stream

	out = []

	removePrecedingNL = ->
		if T.nl out.last()
			# No \n precedes '|' or '.x'
			out.pop()

	# not space, not bracket, not punc, not quote,
	# not comment, not bar, not @, not :,
	nameChar = /[^\s\(\[\{\)\]\};,'"`「」\\\|@\:\.]/
	# like nameChar but can include .
	usedChar = /[^\s\(\[\{\)\]\};,'"`「」\\\|@\:]/
	digit = /[0-9]/
	numChar = /[0-9\.]/
	groupChar = /[\(\[\{\)\]\}]/
	space = RegExp ' '

	indent = 0

	takeName = ->
		cCheck not (stream.peek().match digit), stream.pos,
			'Expected name, got number'
		name = stream.takeMatching nameChar
		cCheck not name.isEmpty(), stream.pos,
			'Expected name, got nothing'
		name

	while ch = stream.peek()
		pos = stream.pos

		if inQuote and ch == '}'
			stream.readChar()
			return out

		match = (regex) ->
			ch.match regex

		token =
			switch
				when (match digit) or (ch == '-' and (stream.peek 1).match digit)
					first = stream.readChar()
					n = stream.takeMatching numChar
					if n.endsWith '.'
						stream.stepBack()
						n = n.withoutEnd '.'
					new T.NumberLiteral pos, "#{first}#{n}"

				when match groupChar
					stream.readChar()
					new GroupPre stream.pos, ch

				when match /[_:@'\.]/
					stream.readChar()
					kind =
						if ch == '.' and stream.maybeTake2More '.'
							'...x'
						else
							"#{ch}x"

					name = takeName()

					if ch == '.' and name.last() == '_'
						check kind != '...x', 'Unexpected _'
						kind = '.x_'
						name = name.withoutEnd '_'

					removePrecedingNL() if ch.isAny ',', '.'
					if ch == "'"
						new T.StringLiteral pos, name
					else
						new T.Name pos, name, kind

				when match nameChar
					name = takeName()
					if name.endsWith '_'
						new T.Name pos, (name.withoutEnd '_'), 'x_'
					else if keywords.metaText.contains name
						lexQuote name, stream, indent
					else if keywords.metaFun.contains name
						new GroupPre pos, name
					else if keywords.useLike.contains name
						stream.takeMatching space
						used = stream.takeMatching usedChar
						new T.Use pos, used, name
					else if keywords.special.contains name
						new T.Special pos, name
					else if name.startsWith '‣'
						stream.takeMatching space
						name2 = takeName()
						new T.Def pos, name, name2
					else
						new T.Name pos, name, 'x'

				when ch == '|'
					stream.readChar()
					removePrecedingNL()
					new GroupPre pos, ch

				when ch == ' '
					stream.takeMatching space
					[]

				when ch == '\\'
					stream.readChar()
					next = stream.peek()

					#if next == '{'
					#	stream.takeUpToAndIncludingString '}#'
					#	#unless stream.hasMore()
					#		# Ate up whole file!
					#		# One final newline will close all indents.
					#	stream.str += '\n\n'

					#else
					stream.takeUpToString '\n'
					check stream.peek() == '\n'
					[]

				when ch == '\n'
					#check stream.prev() != ' ', ->
					#	new Error "Line ends in space at #{pos}"
					stream.takeMatching /\n/ #Skip through blank lines!
					old = indent
					now = (stream.takeMatching /\t/).length
					#check stream.peek() != ' ',
					#	new Error "Line begins with space at #{stream.pos}"
					indent = now
					if now == old
						removePrecedingNL()
						new T.Special pos, '\n'
					else if now < old
						x = (old - now).repeat new GroupPre stream.pos, '←'
						x.push new T.Special stream.pos, '\n'
						x
					else if now == old + 1
						new GroupPre stream.pos, '→'
					else
						cFail pos, "Too indented! Was #{old}, now #{now}"

				when match /[`「"]/
					stream.readChar()
					lexQuote ch, stream, indent

				else
					cFail pos, "Do not recognize char '#{ch}'"


		if token instanceof Array
			out.pushAll token
		else
			out.push token

	out

