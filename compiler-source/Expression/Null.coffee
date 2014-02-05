Expression = require './Expression'

###
Looks like `()`.
Represents `null`.
###
module.exports = class Null extends Expression
	# Only needs pos.
	constructor: (@pos) ->

	# @noDoc
	compile: ->
		[ 'null' ]