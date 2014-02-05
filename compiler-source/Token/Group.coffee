{ groupKinds } = require '../compile-help/language'
Pos = require '../compile-help/Pos'
{ check, type } = require '../help/✔'
Token = require './Token'

###
A Token containing many others.
Currently the only kind is ( ).
###
module.exports = class Group extends Token
	###
	@param openPos [Pos]
	@param closePos [Pos]
	@param kind
	  A key = `../compile-help/language`.groupKinds.
	@param body [Array<Token>]
	###
	constructor: (openPos, closePos, @kind, @body) ->
		type openPos, Pos, closePos, Pos, @kind, String, body, Array
		check @kind in groupKinds
		@pos = openPos

	# @noDoc
	show: ->
		@kind

