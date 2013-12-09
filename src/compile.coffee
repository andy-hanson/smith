lex = require './lex'
parse = require './parse'

#{ SourceNode } = source_map
#{ UseExpression } = expression

#file name without folders
shortName = (fullName) ->
	(fullName.split '/').pop()

compile = (string, inName, outName) ->
	###
	Produces the output { code, map }.
	###
	type string, String
	type inName, String
	type outName, String
	check (inName.endsWith '.smith'), ->
		'Input must be a .smith file!'

	try
		shortIn = shortName inName
		shortOut = shortName outName
		typeName = shortIn.withoutEnd '.smith'

		tokens =
			lex string
		expression =
			parse tokens, typeName

		node =
			expression.toNode shortIn, '\t'

		open = """
			// Generated by smith from #{inName}
			//# sourceMappingURL=#{shortOut}.map

			"use strict";

			var _prelude = require('smith-prelude');
			var _f = _prelude.fun;
			var _b = _prelude.bind;
			var _s = _prelude.string;
			var _c = _prelude.checkExists;
			var Globe = global;

			module.exports = _prelude.type('#{typeName}', function() {

			"""

		close = """

			});
		"""

		node.prepend open
		node.add close

		node.toStringWithSourceMap { file: shortIn }

	catch error
		error.message = "Error compiling #{inName}: #{error.message}"
		throw error



test = ->
	src = '''
Type.new 'Singleton',
	-method-missing-private |name
		(name.startsWith '=').?
			. rest
				name.slice 1

			|val
				def-static-public rest, val


	Type.is me
'''
	src = '''
a
	b


	c

'''

	#console.log(('(' + '\n()'.indent() + ')').indent())



	#throw up


	tokens = lex src
	console.log "TOKENS:"
	tokens.forEach (tok) -> console.log tok
	console.log '\n'
	console.log "PARSED:"
	parsed = parse tokens
	#console.log parsed

	parsed.eachSub (sub) ->
		console.log sub

	c = compile src, 'file', 'out'
	console.log "COMPILED:\n#{c.code}"


	#writeCompiled 'smith/test.smith'

module.exports = compile

###

test = ->
	old_src = '''
+crop | min max
	(< min).?
		min
	|
		(> max).? { max }, { me }

'''

	src = '{}\n'

	#list.map |a { a }, |b { b }

	tokens = lex src, 'test'
	tokens = tokens.slice 0, tokens.length - 1
	#console.log tokens
	#console.log '\n'

	parser = new Parser
	parsed = parser.expressions tokens
	#console.log parsed

	console.log '\n'
	node = parsed.toNode 'test'

	console.log node
	console.log '\n'
	console.log node.toStringWithSourceMap { file: 'test.js' }
###
