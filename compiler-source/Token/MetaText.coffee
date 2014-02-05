keywords = require '../compile-help/keywords'
Pos = require '../compile-help/Pos'
{ check, type } = require '../help/✔'
Group = require './Group'
Token = require './Token'

###
@text should be a StringLiteral or quote Group.
###
module.exports = class MetaText extends Token
	###
	@param pos [Pos]
	@param kind [String]
	@param text [Token]
	###
	constructor: (@pos, @kind, @text) ->
		type @pos, Pos, @kind, String, @text, Token
		check @kind in keywords.metaText

	# @noDoc
	show: ->
		@kind
