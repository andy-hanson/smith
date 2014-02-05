{ SourceNode } = require 'source-map'
{ abstract, type } =  require '../help/✔'
Pos = require '../compile-help/Pos'
Context = require './Context'

###
Represents the meaning of the source code.
All must have @pos and @compile()
###
module.exports = class Expression
	###
	A SourceNode with my @pos,
	the context's `fileName()`,
	and the `chunk` of JavaScript code.
	@param chunk [Chunk]
	  Chunk = JavaScript code, a SourceNode, or an Array of chunks.
	@return [SourceNode]
	###
	nodeWrap: (chunk, context) ->
		type context, Context
		new SourceNode @pos.line(), @pos.column(), context.fileName(), chunk

	###
	Return a SourceNode representing this Expression.
	@return [SourceNode]
	###
	toNode: (context) ->
		type context, Context
		@nodeWrap (@compile context), context

	###
	Produce a Chunk of JavaScript for this Expression.
	@abstract
	@return [Chunk]
	  Chunk = JavaScript code, a SourceNode, or an Array of chunks.
	###
	compile: (context) ->
		abstract()
