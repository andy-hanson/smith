StringMap = require '../help/StringMap'
keywords = require './keywords'

###
Maps escapes to what they represent.
###
@quoteEscape = new StringMap
	't': '\t'
	'n': '\n'
	'{': '{'
	'"': '"'
	'\\': '\\'

###
Character classes used during tokenization.
###
@char =
	# Illegal to use these characters.
	reserved:
		/[\[\[\]\{\}#%&,;]/

	precedesName:
		/[_:@'\.]/
	# Not _, space, bracket, punc, quote, \, |, @, :, or dot.
	name:
		/[^_\s\(\[\{\)\]\};,'"`\\\|@\:\.]/
	# Like nameChar but can include dot.
	used:
		/[^\s\(\[\{\)\]\};,'"`\\\|@\:]/
	digit:
		/[0-9]/
	number:
		/[0-9\.]/
	groupPre:
		/[\(\)]/
	space:
		RegExp ' '

###
Maps group openers to closers.
###
@groupMatch =
	'(': ')'
	'→': '←'

@groupKinds =
	[ '(', '→', '"', '|' ].concat keywords.metaFun

@nameKinds =
	['x', '_x', 'x_', '.x', '.x_', '@x', ':x', '$x', '...x']
