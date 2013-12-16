E = require './Expression'
T = require './Token'
{ cCheck } = require './CompileError'
StringMap = require './StringMap'

module.exports = class Locals
	constructor: ->
		@names = new StringMap # names -> Locals
		@frames = [] # each frame is a list of Locals
		@addFrame()

	addFrame: ->
		@frames.push []

	_add: (local, canRepeat) ->
		type local, E.Local
		@frames.last().push local
		unless canRepeat
			check not (@names.has local.name), =>
				"Already have local #{local}, it's #{@names.get local.name}"
		@names.add local.name, local

	addLocal: (local) ->
		@_add local, no

	addLocalMayShadow: (local) ->
		@_add local, yes

	popFrame: ->
		last = @frames.pop()
		last.forEach (local) =>
			@names.delete local.name

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
		x = @names.maybeGet name.text

	getIt: (pos) ->
		cCheck (@names.has 'it'), pos,
			"No local 'it'"
		@names.get 'it'

	toString: ->
		"<locals #{@names.toString()}>"

