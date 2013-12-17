T = require '../Token'
Stream = require './Stream'
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
				read.tail() # skip initial newline
			else
				read

		getInterpolatedGroup = ->
			check canInterpolate
			lit = new T.StringLiteral stream.pos, text
			out.push lit
			new T.Group startPos, stream.pos, '"', out

		x =
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
					fail

		if indented
			[ x, (new T.Special stream.pos, '\n') ]
		else
			x

	loop
		ch = stream.readChar()

		cCheck ch?, stream.pos, ->
			"Unclosed quote starting at #{startPos}"

		if ch == '\\' and quoteType != '`'
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
			unless indented
				throw new Error "Quote at #{startPos} not closed."
			# Read an indented section.
			nowIndent = (stream.takeMatching /\t/).length
			if nowIndent < quoteIndent
				return finish()
			else
				read += '\n' + '\t'.repeated nowIndent - quoteIndent

		else if ch == closeQuote and not indented
			return finish()

		else
			read += ch
