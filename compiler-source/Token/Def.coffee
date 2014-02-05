Pos = require '../compile-help/Pos'
{ check, type } = require '../help/✔'
{ startsWith } = require '../help/str'
Token = require './Token'

###
Looks like ‣name name2.
Followed by a FunDef.
###
module.exports = class Def extends Token
	###
	@param name [String]
	  What immediately follows `‣`.
	@param name2 [String]
	  The name of what is defined.
	###
	constructor: (@pos, @name, @name2) ->
		type @pos, Pos, @name, String, @name2, String
		check startsWith @name, '‣'

	# @noDoc
	show: ->
		"‣#{@name} #{@name2}"
