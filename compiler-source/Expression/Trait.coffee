{ type } =  require '../help/✔'
Call = require './Call'
DefLocal = require './DefLocal'
Expression = require './Expression'
Use = require './Use'

###
Looks like `trait Trait-Class`.
Represents inheriting a trait.
###
module.exports = class Trait extends Expression
	###
	@param use [E.Use]
		This will be inherited as a triat.
	###
	constructor: (@use) ->
		type use, Use
		{ @pos } = use

	# @noDoc
	compile: (context) ->
		def =
			new DefLocal @use.local, @use
		trait =
			Call.me @pos, 'trait', [ @use.local ]

		[	(def.toNode context),
			'\n', context.indent(),
			(trait.toNode context) ]