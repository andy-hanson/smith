lex = require './lex'
parse = require './parse'
AllModules = require './AllModules'
Pos = require './Pos'
path = require 'path'
E = require './Expression'
Options = require './Options'


shortName = (fullName) ->
	(fullName.split '/').pop()

###
Produces the output { code, map }.
###
module.exports = (string, inName, outName, options) ->
	type string, String
	type inName, String
	check (inName.endsWith '.smith'), ->
		"Input must be a .smith, not #{inName}"
	type outName, String
	type options, Options
	allModules = options.allModules()
	type allModules, AllModules
	printModuleDefines = options.printModuleDefines()
	type printModuleDefines, Boolean

	shortIn = shortName inName
	shortOut = shortName outName
	typeName = shortIn.withoutEnd '.smith'

	tokens =
		lex string
	[ sooper, autoUses, fun ] =
		parse tokens, typeName, inName, options
	type sooper, E.Expression
	type autoUses, Array
	type fun, E.Expression

	prelude =
		allModules. get 'Smith-Prelude', Pos.start, inName

	# TODO: not hard-coded
	fullIn = 'source/' + inName
	fullOut = 'js/' + outName

	sourceMapRel = path.relative fullOut, fullIn

	toNode = (x) ->
		x.toNode new E.Context options, sourceMapRel, ''

	superNode =
		toNode sooper

	autos =
		autoUses.filter (u) ->
			u.local.everUsed()
		.map(toNode)
		.interleavePlus ';\n'

	classConstruct =
		"_p.class('#{typeName}', #{superNode}, "

	open = [
		"""
		// Generated by smith from #{inName}
		//# sourceMappingURL=#{shortOut}.map
		"use strict"#{';'}
		#{if printModuleDefines then "console.log('→ #{typeName}...');" else ''}
		var _p = require('#{prelude}'), _b = _p.bind, _c = _p.call, _f = _p.fun,
			_it = _p.itMethod, _l = _p.lazy, _n = _p.checkNumberOfArguments,
			_s = _p.string, _a = _p.argument, _o = _p.optionalArgumentTag;\n

		""", autos, 'module.exports = ', classConstruct ]

	close = """

		)#{';'}
		#{if printModuleDefines then "console.log('← #{typeName}...');" else ''}
	"""

	node = toNode fun
	node.prepend open
	node.add close

	node.toStringWithSourceMap { file: shortIn }
