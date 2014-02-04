{ type } =  require '../help/✔'
T = require '../Token'
Expression = require './Expression'
###
_func
(unrelated to keyword 'it')
###
module.exports = class ItFunDef extends Expression
	constructor: (@name) ->
		type @name, T.Name
		{ @pos } = @name

	compile: (context) ->
		[ "_it('", @name.text, "')" ]