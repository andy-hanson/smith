Pos = require '../compile-help/Pos'
{ nameKinds } = require '../compile-help/language'
{ check, type } = require '../help/✔'
Token = require './Token'

###
Any one of the forms in `Name.kinds`,
where `x` is any sequence of valid name characters.
###
module.exports = class Name extends Token
	###
	@param kind [String]
	  What member of `../compile-help/language`.nameKinds describes me.
	###
	constructor: (@pos, @text, @kind) ->
		type @pos, Pos, @text, String
		check @kind in nameKinds

	# @noDoc
	show: ->
		@kind
