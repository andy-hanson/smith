lex = require './lex'
parse = require './parse'
compile = require './compile'

module.exports = ->
	s = '''
		a |b
			c
	'''

	tokens = lex s
	#console.log tokens

	#console.log parse tokens, 'test'

	console.log (compile s, 'test.smith', 'out').code
	#console.log lex s
	#console.log parse (lex s), 'test'
