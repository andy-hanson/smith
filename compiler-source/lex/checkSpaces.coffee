{ cFail } = require '../compile-help/✔'
{ endsWith, startsWith, trimLeftChar, withoutStart } = require '../help/str'
Pos = require '../compile-help/Pos'

###
Forbid non-tab indentation.
If --nazi, forbid trailing whitespace and double spaces.
###
module.exports = checkSpaces = (str, options) ->
	for line, lineNumber in str.split '\n'
		lineNumber += 1 # want 1-indexed
		minusTabs = trimLeftChar line, '\t'

		#if startsWith minusTabs, ' '
		#	pos = new Pos lineNumber, 1
		#	cFail pos, """
		#		Line uses spaces to indent.
		#		Make sure your editor doesn't translate tabs to spaces.
		#		"""
		if options.nazi()
		#	if endsWith line, ' '
		#		pos = new Pos lineNumber, line.length - 1
		#		cFail pos, """
		#			Line ends in a space.
		#			See if your editor can automatically trim trailing white space on save.
		#			"""
			if (index = line.indexOf '  ') != -1
				pos = new Pos lineNumber, index
				cFail pos, 'Two spaces in a row.'
