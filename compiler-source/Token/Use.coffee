{ cCheck } = require '../compile-help/✔'
Pos = require '../compile-help/Pos'
{ type } = require '../help/✔'
{ last } = require '../help/list'
Token = require './Token'

###
Looks like `use My/Module.Part`.
Also includes `use!`, `super`, and `trait`.
@todo '.' in use
###
module.exports = class Use extends Token
	###
	@param pos [Pos]
	@param used [String]
	@param kind [String]
	###
	constructor: (@pos, @used, @kind) ->
		type @pos, Pos, @used, String, @kind, String
		cCheck (not ('.' in @used)), @pos,
			"TODO: '.' in use'"

	###
	Whether this should be parsed into a lazy local.
	###
	lazy: ->
		@kind == 'use'

	###
	The part of the use after '/'
	###
	shortName: ->
		last (@used.split '/')

	# @noDoc
	show: ->
		"<use #{@used}>"
