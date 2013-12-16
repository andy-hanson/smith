lex = require './lex'
parse = require './parse'
AllModules = require './AllModules'
Pos = require './Pos'

shortName = (fullName) ->
	(fullName.split '/').pop()

module.exports = (string, inName, outName, opts) ->
	###
	Produces the output { code, map }.
	###
	type string, String
	type inName, String
	check (inName.endsWith '.smith'), ->
		"Input must be a .smith, not #{inName}"
	type outName, String
	{ allModules, printModuleDefines } = opts
	type allModules, AllModules
	type printModuleDefines, Boolean

	shortIn = shortName inName
	shortOut = shortName outName
	typeName = shortIn.withoutEnd '.smith'

	tokens =
		lex string
	[ iz, fun ] =
		parse tokens, typeName, inName, allModules

	prelude =
		allModules. get 'Prelude', Pos.start, inName

	izNode =
		if iz then iz.toNode inName, '' else 'null'
	#doessesNode =
	#	(doesses.map (does) -> does.toNode inName, '').interleave ', '

	classConstruct =
		"_prelude.class('#{typeName}', #{izNode},"

	open = """
		// Generated by smith from #{inName}
		//# sourceMappingURL=#{shortOut}.map
		"use strict"

		var _prelude = require('#{prelude}');
		var _f = _prelude.fun;
		var _b = _prelude.bind;
		var _it = _prelude.itMethod;
		var _s = _prelude.string;
		var _l = _prelude.lazy#{';'}
		#{if printModuleDefines then "console.log('→ #{typeName}...');" else ''}
		module.exports = #{classConstruct}
	"""

	close = """

		)#{';'}

		#{if printModuleDefines then "console.log('← #{typeName}...');" else ''}
	"""

	node = fun.toNode inName, ''
	node.prepend open
	node.add close

	node.toStringWithSourceMap { file: shortIn }
