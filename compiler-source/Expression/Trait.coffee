{ type } =  require '../help/✔'
Call = require './Call'
DefLocal = require './DefLocal'
Expression = require './Expression'
Use = require './Use'

module.exports = class Trait extends Expression
	constructor: (@use) ->
		type use, Use
		{ @pos } = use

	compile: (context) ->
		def = new DefLocal @use.local, @use
		trait = Call.me @pos, 'trait', [ @use.local ]
		[	(def.toNode context),
			'\n', context.indent,
			(trait.toNode context) ]