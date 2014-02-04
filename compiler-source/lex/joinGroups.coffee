T = require '../Token'
GroupPre = require './GroupPre'
{ cCheck, cFail } = require '../compile-help/✔'
keywords = require '../compile-help/keywords'
{ check, type } = require '../help/✔'
{ isEmpty, last } = require '../help/list'
#{ endsWith, startsWith } = require '../help/str'

module.exports = (tokens) ->
	stack = []
	current = [] # Tokens to form this body
	opens = [] # GroupPres

	newLevel = (open) ->
		type open, GroupPre
		opens.push open
		stack.push current
		current = []

	finishLevel = (result) ->
		current = stack.pop()
		current.push result

	specialOpenKinds =
		[ '|', 'in', 'out', 'eg', 'sub-eg' ]
	openKinds =
		[ '(', '→', '|' ].concat keywords.metaFun
	blockCloseKinds =
		[ '←' ]
	closeKinds =
		[ ')' ].concat blockCloseKinds

	for tok in tokens
		if tok instanceof GroupPre
			{ pos, kind } = tok
			if kind in openKinds
				newLevel tok
			else if kind in closeKinds
				cCheck (not isEmpty opens), pos, ->
					"Unexpected closing #{kind}"
				open = opens.pop()

				cCheck T.Group.match[open.kind] == kind, tok.pos, ->
					"#{open} does not match #{tok}"

				finishLevel new T.Group \
					open.pos, tok.pos, open.kind, current

				if kind == '←'
					if (last opens)?.kind in specialOpenKinds
						open = opens.pop()
						finishLevel new T.Group \
							open.pos, tok.pos, open.kind, current
			else
				fail()

		else
			if tok instanceof T.Group # From Quotes
				tok.body = module.exports tok.body
			current.push tok

	unless isEmpty opens
		cFail (last opens).pos, "Never closed #{opens.last().kind}"
	check isEmpty stack

	current