{ type } =  require '../help/✔'
Pos = require '../compile-help/Pos'
Expression = require './Expression'

module.exports = class Me extends Expression
	constructor: (@pos) ->
		type @pos, Pos

	toString: ->
		'me'

	compile: ->
		'this'