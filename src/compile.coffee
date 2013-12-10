lex = require './lex'
parse = require './parse'

shortName = (fullName) ->
	(fullName.split '/').pop()

module.exports = (string, inName, outName, isStd) ->
	###
	Produces the output { code, map }.
	###
	type string, String
	type inName, String
	type outName, String
	type isStd, Boolean
	check (inName.endsWith '.smith'), ->
		"Input must be a .smith, not #{inName}"

	try
		shortIn = shortName inName
		shortOut = shortName outName
		typeName = shortIn.withoutEnd '.smith'

		tokens =
			lex string
		expression =
			parse tokens, typeName

		node =
			expression.toNode inName, '\t\t'


		prelude =
			if isStd
				nest =
					inName.count '/'
				if nest > 0
					('../'.repeated nest) + 'prelude'
				else
					'./prelude'
			else
				todo()

		open = """
			// Generated by smith from #{inName}
			//# sourceMappingURL=#{shortOut}.map
			"use strict";
			if (typeof define !== 'function')
				var define = require('amdefine')(module);

			define(function(require) {
				var _prelude = require('#{prelude}');
				var _f = _prelude.fun;
				var _b = _prelude.bind;
				var _s = _prelude.string;
				var _l = _prelude.lazy;

				return _prelude.type('#{typeName}', function() {

			"""

		close = """

				});
			});
		"""

		node.prepend '\t\t'
		node.prepend open
		node.add close

		node.toStringWithSourceMap { file: shortIn }

	catch error
		error.message = "Error compiling #{inName}: #{error.message}"
		throw error
