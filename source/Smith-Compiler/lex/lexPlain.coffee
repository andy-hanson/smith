T = require '../Token'
Stream = require './Stream'
GroupPre = require './GroupPre'
lexQuote = require './lexQuote'
{ cFail, cCheck } = require '../CompileError'

keywords =
	[ 'use', 'use!', 'me', '∙', '∘', 'doc', 'in', 'out', 'eg', 'how' ]

module.exports = (stream, inQuote) ->
	type stream, Stream

	out = []

	removePrecedingNL = ->
		if T.nl out.last()
			# No \n precedes '|' or '.x'
			out.pop()

	# not space, not bracket, not punc, not quote,
	# not comment, not bar, not @, not :,
	nameChar = /[^\s\(\[\{\)\]\}\.;,'"`「」#\|@\:]/
	digit = /[0-9]/
	numChar = /[0-9\.]/
	groupChar = /[\(\[\{\)\]\}]/

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

		token =
			if ch.match groupChar
				stream.readChar()
				new GroupPre stream.pos, ch

			else if (ch.match digit) or \
					((ch == '-') and stream.peek(1).match digit)
				first = stream.readChar()
				n = stream.takeMatching numChar
				if n.endsWith '.'
					stream.stepBack()
					n = n.withoutEnd '.'
				new T.NumberLiteral pos, "#{first}#{n}"

			else if ['_', ':', ',', "'", '.'].contains ch
				stream.readChar()
				kind =
					if ch == '.' and stream.maybeTake2More '.'
						'...x'
					else
						"#{ch}x"

				name = takeName()

				if ch == '.' and stream.maybeTake '_'
					check kind != '...x', 'Unexpected _'
					kind = '.x_'

				removePrecedingNL() if [',', '.'].contains ch
				if ch == "'"
					new T.StringLiteral pos, name
				else
					new T.Name pos, name, kind

			else if ch.match nameChar
				name = takeName()
				if stream.maybeTake '_'
					new T.Name pos, name, 'x_'
				else if name in keywords
					switch name
						when 'use', 'use!'
							stream.takeMatching /\s/
							used = stream.takeNotMatching /\n/
							new T.Use pos, used, name == 'use'
						when 'doc', 'how'
							lexQuote name, stream, indent
						when 'in', 'out', 'eg'
							new GroupPre pos, name
						else
							new T.Special pos, name
				else
					if name.startsWith '‣'
						stream.takeMatching /\s/
						name2 = takeName()
						new T.Def pos, name, name2
					else
						new T.Name pos, name, 'x'

			else if ch == '|'
				stream.readChar()
				removePrecedingNL()
				new GroupPre pos, ch

			else if ch == ' '
				stream.takeMatching /\s/
				[]

			else if ch == '#'
				stream.readChar()
				next = stream.peek()

				if next == '{'
					stream.takeUpToAndIncludingString '}#'
					#unless stream.hasMore()
						# Ate up whole file!
						# One final newline will close all indents.
					stream.str += '\n\n'

				else
					stream.takeUpToString '\n'
					check stream.peek() == '\n'
				[]

			else if ch == '\n'
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
					x = (old - now).repeat new GroupPre stream.pos, '<-'
					x.push new T.Special stream.pos, '\n'
					x
				else if now == old + 1
					#lexPlain stream, '->'
					new GroupPre stream.pos, '->'
				else
					cFail pos, "Too indented! Was #{old}, now #{now}"

			else if ['`', '「', '"'].contains ch
				stream.readChar()
				lexQuote ch, stream, indent

			else
				cFail pos, "Do not recognize char '#{stream.peek()}'"

		if token instanceof Array
			out.pushAll token
		else
			out.push token

	out

