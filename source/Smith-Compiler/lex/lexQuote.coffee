T = require '../Token'
Stream = require './Stream'
GroupPre = require './GroupPre'
{ cFail, cCheck } = require '../CompileError'

module.exports = (quoteType, stream, oldIndent) ->
	type quoteType, String
	type stream, Stream
	type oldIndent, Number

	escape =
		't': '\t'
		'n': '\n'

	read = ''
	out = []
	startPos = stream.pos

	indented =
		stream.peek() == '\n'
	canEscape =
		quoteType != '`'
	canInterpolate =
		not quoteType.isAny '「', '`'
	quoteIndent =
		oldIndent + 1

	closeQuote =
		unless indented
			switch quoteType
				when '`', '"'
					quoteType
				when '「'
					'」'
				else
					fail()

	finish = ->
		text =
			if indented
				read.tail().trimRight() # skip initial newline
			else
				read

		getInterpolatedGroup = ->
			check canInterpolate
			literal = new T.StringLiteral stream.pos, text
			if out.isEmpty()
				literal
			else
				out.push literal
				new T.Group startPos, stream.pos, '"', out

		quote =
			switch quoteType
				when '"'
					getInterpolatedGroup()
				when '`'
					kind =
						if indented then 'indented' else 'plain'
					new T.JavascriptLiteral startPos, text, kind
				when '「'
					new T.StringLiteral startPos, text
				when 'doc', 'how'
					new T.MetaText startPos, quoteType, getInterpolatedGroup()
				else
					fail()

		quote

	loop
		ch = stream.readChar()

		cCheck ch?, startPos, 'Unclosed quote.'

		if ch == '\\' and canEscape
			next = stream.readChar()
			read += (escape[next] or next)

		else if ch == '{' and canInterpolate
			out.push new T.StringLiteral stream.pos, read
			read = ''
			startPos =
				stream.pos
			interpolated =
				(require './lexPlain') stream, yes

			out.push new T.Group startPos, stream.pos, '(', interpolated

		else if ch == '\n'
			cCheck indented, startPos, 'Unclosed quote.'
			# Read an indented section.
			nowIndent = (stream.takeMatching /\t/).length
			if nowIndent == 0 and stream.peek() == '\n'
				read += '\n'
			else if nowIndent < quoteIndent
				# undo reading those tabs
				stream.stepBack nowIndent + 1
				check stream.peek() == '\n'
				return finish()
			else
				read += '\n' + '\t'.repeated nowIndent - quoteIndent

		else if ch == closeQuote and not indented
			return finish()

		else
			read += ch
