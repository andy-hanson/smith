T = require '../Token'
Stream = require './Stream'
GroupPre = require './GroupPre'
{ cFail, cCheck } = require '../compile-help/✔'
keywords = require '../compile-help/keywords'
{ check, type } = require '../help/✔'
{ isEmpty } = require '../help/list'
{ repeated, withoutStart } = require '../help/str'
{ quoteEscape } = require '../compile-help/language'

module.exports = (quoteType, stream, oldIndent) ->
	type quoteType, String, stream, Stream, oldIndent, Number

	tokenize = require './tokenize'

	read = ''
	out = [ ]
	startPos = stream.pos()

	indented =
		stream.peek() == '\n'
	canEscape =
		quoteType != '`'
	canInterpolate =
		quoteType != '`'
	quoteIndent =
		oldIndent + 1

	closeQuote =
		unless indented
			switch quoteType
				when '`', '"'
					quoteType
				else
					cFail startPos, "Bad quote type #{quoteType}"

	finish = ->
		text =
			if indented
				(withoutStart read, '\n').trimRight() # skip initial newline
			else
				read

		getInterpolatedGroup = ->
			check canInterpolate
			literal = new T.StringLiteral stream.pos(), text
			if isEmpty out
				literal
			else
				out.push literal
				new T.Group startPos, stream.pos(), '"', out

		if quoteType in keywords.metaText
			new T.MetaText startPos, quoteType, getInterpolatedGroup()
		else
			switch quoteType
				when '"'
					getInterpolatedGroup()
				when '`'
					kind =
						if indented then 'indented' else 'plain'
					new T.JavascriptLiteral startPos, text, kind
				else
					fail()

	loop
		ch = stream.readChar()

		cCheck ch?, startPos, 'Unclosed quote.'

		if ch == '\\' and canEscape
			next = stream.readChar()
			if quoteEscape.has next
				read += quoteEscape.get next
			else
				cFail startPos, "No need to escape '#{next}'"

		else if ch == '{' and canInterpolate
			out.push new T.StringLiteral stream.pos(), read
			read = ''
			startPos =
				stream.pos()
			interpolated =
				tokenize stream, yes

			out.push new T.Group startPos, stream.pos(), '(', interpolated

		else if ch == '\n'
			cCheck indented, startPos, 'Unclosed quote.'
			# Read an indented section.
			nowIndent = (stream.takeWhile /\t/).length
			if nowIndent == 0 and stream.peek() == '\n'
				read += '\n'
			else if nowIndent < quoteIndent
				# undo reading those tabs and that new line.
				stream.stepBack nowIndent + 1
				check stream.peek() == '\n'
				return finish()
			else
				read += '\n' + repeated '\t', nowIndent - quoteIndent

		else if ch == closeQuote and not indented
			return finish()

		else
			read += ch
