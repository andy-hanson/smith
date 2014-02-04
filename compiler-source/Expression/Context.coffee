{ type } =  require '../help/✔'
Options = require '../run/Options'
{ repeated } = require '../help/str'

module.exports = class Context
	constructor: (@options, @fileName, @indent) ->
		type @options, Options, @fileName, String, @indent, String

	indented: (n = 1) ->
		new Context @options, @fileName, "#{repeated '\t', n}#{@indent}"