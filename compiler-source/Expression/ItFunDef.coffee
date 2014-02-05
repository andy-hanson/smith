{ type } =  require '../help/✔'
T = require '../Token'
Expression = require './Expression'

###
Looks like `_func`.
Basically, `function(x, ...rest) { return x.method(...rest); }`.
Unrelated to keyword 'it'.
###
module.exports = class ItFunDef extends Expression
	###
	@param name [String]
	  Name of method to call on it.
	###
	constructor: (@name) ->
		type @name, T.Name
		{ @pos } = @name

	# @noDoc
	compile: (context) ->
		[ "_it('", @name.text, "')" ]