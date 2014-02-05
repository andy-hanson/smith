Pos = require '../compile-help/Pos'
keywords = require '../compile-help/keywords'
{ check, type } = require '../help/✔'
Token = require './Token'

###
A token with special meaning, such as a keyword.
###
module.exports = class Special extends Token
	###
	@param kind [String]
	  What member of `../compile-help/keywords` we are.
	###
	constructor: (@pos, @kind) ->
		type @pos, Pos, @kind, String
		check @kind in keywords.special

	# @noDoc
	show: ->
		x =
			if @kind == '\n'
				'\\n'
			else
				@kind
		"[#{x}]"
