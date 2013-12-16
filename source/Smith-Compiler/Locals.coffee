E = require './Expression'
T = require './Token'
{ cCheck } = require './CompileError'

module.exports = class Locals
	constructor: ->
		@names = { } # maps strings to Locals
		@frames = [] # each frame is a list of Locals
		@addFrame()

	addFrame: ->
		@frames.push []

	_add: (local, canRepeat) ->
		type local, E.Local
		@frames.last().push local
		unless canRepeat
			check not @names[local.name]?, =>
				"Already have local #{local}, it's #{@names[local.name]}"
		@names[local.name] = local

	addLocal: (local) ->
		@_add local, no

	addLocalMayShadow: (local) ->
		@_add local, yes

	popFrame: ->
		last = @frames.pop()
		last.forEach (local) =>
			delete @names[local.name]

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

	getIt: (pos) ->
		cCheck (@names.hasOwnProperty 'it'), pos,
			"No local 'it'"
		@names['it']

	toString: ->
		"<locals #{Object.keys @names}>"

