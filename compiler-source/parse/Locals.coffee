E = require '../Expression'
T = require '../Token'
{ cCheck } = require '../compile-help/✔'
StringMap = require '../help/StringMap'
Pos = require '../compile-help/Pos'
{ check, type } =  require '../help/✔'
{ last } = require '../help/list'

module.exports = class Locals
	constructor: ->
		@names = new StringMap # names -> Locals
		@frames = [] # each frame is a list of Locals
		@addFrame()

	addFrame: ->
		@frames.push []

	_add: (local, canRepeat) ->
		type local, E.Local
		(last @frames).push local
		unless canRepeat
			check not (@names.has local.name), =>
				"Already have local #{local}, it's #{@names.get local.name}"
		@names.add local.name, local

	addLocal: (local) ->
		@_add local, no

	addLocalMayShadow: (local) ->
		@_add local, yes

	popFrame: ->
		@frames.pop().forEach (local) =>
			@names.delete local.name

	withFrame: (fun) ->
		@addFrame()
		res = fun()
		@popFrame()
		res

	withLocal: (loc, fun) ->
		@withLocals [loc], fun

	withLocals: (locals, fun) ->
		@withFrame =>
			locals.forEach (local) =>
				@addLocal local
			fun()

	get: (name) ->
		type name, T.Name
		x = @names.maybeGet name.text

	getIt: (pos) ->
		type pos, Pos
		cCheck (@names.has 'it'), pos,
			"No local 'it' ('it' must be a local)"
		@names.get 'it'

	toString: ->
		"<locals #{@names.toString()}>"

