{ SourceNode } = require 'source-map'
{ type } =  require '../help/✔'
Pos = require '../compile-help/Pos'
Context = require './Context'

module.exports = class Expression
	###
	All must have @pos
	All must have compile (produces an array)
	###
	inspect: ->
		@toString()

	nodeWrap: (chunk, context) ->
		type context, Context, context.fileName, String

		new SourceNode \
			@pos.line,
			@pos.column,
			context.fileName,
			chunk

	toNode: (context) ->
		type @pos, Pos, context, Context

		chunk =
			@compile context

		@nodeWrap chunk, context