lex = require './lex'
parse = require './parse'
compile = require './compile'

describe 'compiler', ->
	it 'is cool', ->
		s = '''
			x.fold _+
			x.each log!_
			x.each Console.log!_
		'''
		s = '''
			a
		'''

		tokens = lex s
		parsed = parse tokens, 'file-name'
		console.log compile s, 'in', 'out'
