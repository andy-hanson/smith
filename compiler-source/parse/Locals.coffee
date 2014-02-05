E = require '../Expression'
T = require '../Token'
{ cCheck } = require '../compile-help/✔'
StringMap = require '../help/StringMap'
Pos = require '../compile-help/Pos'
{ check, type } =  require '../help/✔'
{ last } = require '../help/list'

###
Stores all local variables available.
###
module.exports = class Locals
	# Starts empty.
	constructor: ->
		@names = new StringMap # names -> Locals
		@frames = [ ] # each frame is a list of Locals
		@_addFrame()

	###
	Create a new frame of locals.
	@private
	###
	_addFrame: ->
		@frames.push [ ]

	###
	Put `local` in the current frame.
	@private
	###
	_add: (local, canRepeat) ->
		type local, E.Local
		(last @frames).push local
		unless canRepeat
			check not (@names.has local.name), =>
				"Already have local #{local}, it's #{@names.get local.name}"
		@names.add local.name, local

	###
	Put `local` in the current frame.
	###
	addLocal: (local) ->
		@_add local, no

	###
	Some locals may shadow others; e.g. `super Str` when `Str` is auto-imported.
	###
	addLocalMayShadow: (local) ->
		@_add local, yes

	###
	The local of the given name.
	###
	get: (name) ->
		type name, T.Name
		@names.get name.text

	###
	Gets the local named `it`.
	`it` is not allowed as a method name, so never returns `null`.
	###
	getIt: (pos) ->
		type pos, Pos
		cCheck (@names.has 'it'), pos,
			"No local 'it' ('it' must be a local)"
		@names.get 'it'

	###
	Whether a local of the name exists.
	@param name [T.Name]
	###
	has: (name) ->
		@names.has name.text

	###
	Pop the current frame and delete all locals in it.
	@private
	###
	_popFrame: ->
		@frames.pop().forEach (local) =>
			@names.delete local.name

	###
	Run `fun` in a sub-frame that closes after `fun` is done.
	###
	withFrame: (fun) ->
		@_addFrame()
		res = fun()
		@_popFrame()
		res

	###
	Run `fun` in a new frame with a new local.
	###
	withLocal: (loc, fun) ->
		@withLocals [loc], fun

	###
	Run `fun` in a new frame with new locals.
	###
	withLocals: (locals, fun) ->
		@withFrame =>
			locals.forEach (local) =>
				@addLocal local
			fun()

