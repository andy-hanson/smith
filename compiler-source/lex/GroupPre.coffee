T = require '../Token'

module.exports = class GroupPre extends T.Token
	constructor: (@pos, @kind) ->
		null

	show: ->
		@kind
