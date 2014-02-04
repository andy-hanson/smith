{ cFail } = require '../compile-help/✔'
{ endsWith, startsWith, trimLeftChar, withoutStart } = require '../help/str'
Pos = require '../compile-help/Pos'

module.exports = (str, options) ->
	###
	Forbid tab indentation or trailing whitespace.
	###
	for line, lineNumber in str.split '\n'
		minusTabs = trimLeftChar line, '\t'

		if startsWith minusTabs, ' '
			pos = new Pos lineNumber+1, 1
			cFail pos, """
				Line uses spaces to indent.
				Make sure your editor doesn't translate tabs to spaces.
				"""
		if options.nazi()
			if endsWith line, ' '#/[^\S\n]/ # reges: not (not whatspace or \n) = non-\n whitespace
				pos = new Pos lineNumber+1, line.length - 1
				cFail pos, """
					Line ends in a space.
					See if your editor can automatically trim trailing white space on save.
					"""
			if (index = line.indexOf '  ') != -1
				pos = new Pos lineNumber+1, index
				cFail pos, """
					Two spaces in a row.
				"""