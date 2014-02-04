Expression = require './Expression'

module.exports = class Null extends Expression
	constructor: (@pos) ->

	toString: ->
		"null"

	compile: ->
		[ 'null' ]