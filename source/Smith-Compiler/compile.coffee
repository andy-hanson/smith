lex = require './lex'
parse = require './parse'
AllModules = require './AllModules'
Pos = require './Pos'
path = require 'path'

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
	[ sooper, autoUses, fun ] =
		parse tokens, typeName, inName, allModules

	prelude =
		allModules. get 'Smith-Prelude', Pos.start, inName

	# TODO: not hard-coded
	fullIn = 'source/' + inName
	fullOut = 'js/' + outName

	sourceMapRel = path.relative fullOut, fullIn

	toNode = (x) ->
		x.toNode sourceMapRel, ''

	superNode =
		if sooper then toNode sooper else 'null'

	autos =
		(autoUses.map toNode).interleavePlus ';\n'

	classConstruct =
		"_prelude.class('#{typeName}', #{superNode}, "

	open = [
		"""
		// Generated by smith from #{inName}
		//# sourceMappingURL=#{shortOut}.map
		"use strict"#{';'}
		#{if printModuleDefines then "console.log('→ #{typeName}...');" else ''}
		var _prelude = require('#{prelude}');
		var _f = _prelude.fun;
		var _b = _prelude.bind;
		var _it = _prelude.itMethod;
		var _s = _prelude.string;
		var _l = _prelude.lazy;
		var _nArgs = _prelude.checkNumberOfArguments;
		var _arg = _prelude.argument;
		var _opt = _prelude.optionalArgumentTag;
		var _call = _prelude.call#{';'}

		""", autos, 'module.exports = ', classConstruct ]

	close = """

		)#{';'}
		#{if printModuleDefines then "console.log('← #{typeName}...');" else ''}
	"""

	node = toNode fun
	node.prepend open
	node.add close

	node.toStringWithSourceMap { file: shortIn }
