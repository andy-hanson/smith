E = require './Expression'
T = require './Token'

module.exports = class Locals
	constructor: ->
		@names = { } # maps strings to Locals
		@frames = [] # each frame is a list of Locals
		@addFrame()

	addFrame: ->
		@frames.push []

	addLocal: (local) ->
		type local, E.Local
		@frames.last().push local
		check not @names[local.text]?, =>
			"Already have local #{local}, it's #{@names[local.text]}"
		@names[local.text] = local

	popFrame: ->
		last = @frames.pop()
		last.forEach (local) =>
			delete @names[local.text]

	withLocal: (loc, fun) ->
		@withLocals [loc], fun

	withLocals: (locals, fun) ->
		@addFrame()

		locals.forEach (local) =>
			@addLocal local

		res = fun()

		@popFrame()

		res

	get: (name) ->
		type name, T.Name
		if @names.hasOwnProperty name.text
			@names[name.text]

	toString: ->
		"<locals #{Object.keys @names}>"

