T = require '../Token'
Stream = require './Stream'
lexPlain = require './lexPlain'
lexQuote = require './lexQuote'
GroupPre = require './GroupPre'
{ cCheck, cFail } = require '../CompileError'
Pos = require '../Pos'

checkSpaces = (str) ->
	for line, lineNumber in str.split '\n'
		if line.startsWith ' '
			pos = new Pos lineNumber, 1
			cFail pos, "Line #{lineNumber + 1} starts with a space."
		if line.endsWith ' '
			pos = new Pos lineNumber, line.length - 1
			cFail pos, "Line #{lineNumber + 1} ends with a space."

joinGroups = (tokens) ->
	stack = []
	current = [] # Tokens to form this body
	opens = [] # GroupPres

	new_level = (open) ->
		type open, GroupPre
		opens.push open
		stack.push current
		current = []

	finish_level = (result) ->
		current = stack.pop()
		current.push result

	for tok in tokens
		if tok instanceof GroupPre
			{ pos, kind } = tok
			switch kind
				when '(', '[', '{', '→', '|', 'in', 'out', 'eg'
					new_level tok
				when ')', ']', '}', '←'
					cCheck not opens.isEmpty(), pos, ->
						"Unexpected closing #{kind}"
					open = opens.pop()

					cCheck T.Group.match[open.kind] == kind, tok.pos, ->
						"#{open} does not match #{tok}"

					finish_level new T.Group \
						open.pos, tok.pos, open.kind, current

					if kind.isAny '}', '←'
						if opens.last()?.kind?.isAny '|', 'in', 'out', 'eg'
							open = opens.pop()
							finish_level new T.Group \
								open.pos, tok.pos, open.kind, current

		else
			if tok instanceof T.Group # From Quotes
				tok.body = joinGroups tok.body
			current.push tok

	unless opens.isEmpty()
		cFail opens.last().pos, "Never closed #{opens.last().kind}"
	check stack.isEmpty()
	current

module.exports = (str) ->
	type str, String
	checkSpaces str
	str += '\n'

	stream =
		new Stream str
	plain =
		lexPlain stream
	tokens =
		joinGroups plain

	tokens
