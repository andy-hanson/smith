T = require './Token'
E = require './Expression'
Pos = require './Pos'

class Locals
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

	withLocals: (locals, fun) ->
		@addFrame()

		locals.forEach (local) =>
			@addLocal local

		res = fun()

		@popFrame()

		res

	has: (name) ->
		check T.normalName name
		@names.hasOwnProperty name.text

	toString: ->
		"<locals #{Object.keys @names}>"


class Parser
	constructor: (@typeName) ->
		type @typeName, String
		@locals =
			new Locals
		@pos =
			Pos.start

	all: (tokens) ->
		typeLocal =
			new E.Local new T.Name @pos, @typeName, 'x'
		@locals.addLocal typeLocal


		b = @block tokens
		b.subs.unshift new E.DefLocal typeLocal, E.me @pos#new E.Me @pos
		b

	block: (tokens) ->
		type tokens, Array

		exprs =
			(tokens.splitBy T.nl).filter (toks) ->
				not toks.isEmpty()

		parsed =
			exprs.map (toks) =>
				@expression toks

		new E.Block @pos, parsed


	expression: (tokens) ->
		type tokens, Array

		if tokens.isEmpty()
			return new E.Void @pos

		tok0 = tokens[0]

		if tok0 instanceof T.Use
			@use tokens
		else if tok0 instanceof T.Special and tok0.type == '∙'
			@defLocal tokens.tail()
		else
			slurped = []
			until tokens.isEmpty()
				tok0 = tokens[0]
				x =
					if T.dotLikeName tok0
						tokens = tokens.tail()
						switch tok0.type
							when '.x'
								pop = slurped.pop()
								if pop?
									new E.Call pop, tok0, []
								else
									throw new Error "Unexpected #{tok0}"
							when '.x_'
								new E.BoundFunc slurped.pop(), tok0
							else
								fail()
					else
						tokens = tokens.tail()
						@soloExpression tok0

				type x, E.Expression
				slurped.push x

			[ e0, tail ] = slurped.unCons()
			if e0 instanceof E.Call
				check e0.args.isEmpty()
				e0.args = tail
				e0
			else
				if tail.isEmpty()
					e0
				else
					new E.Call.of e0, tail

	soloExpression: (t) ->
		type t, T.Token

		unexpected = ->
			throw new Error "Unexpected #{t}"

		@pos = t.pos

		switch t.constructor
			when T.Name
				switch t.type
					when 'x'
						if @locals.has t
							new E.Local t
						else
							E.Call.me t, []
					when '_x'
						new E.ItFuncDef t
					when 'x_'
						new E.BoundFunc.me t
					else
						unexpected t
			when T.Group
				switch t.type
					when '|'
						@func t.body
					when '('
						new E.Parend @expression t.body
					when '['
						unexpected t
					when '{'
						@curlied t
					when '"'
						new E.Quote t.pos, t.body.map (part) =>
							@soloExpression part
			when T.Special
				switch t.type
					when '|'
						@funcAndRest tail
					#when 'me'
					#	new E.Me t.pos
					when 'arguments'
						new E.Arguments t.pos
					else
						unexpected t
			else
				if t instanceof T.Literal
					new E.Literal t
				else
					unexpected t

	###
	TODO: 'it'
	###
	curlied: (curlied) ->
		body =
			@block curlied.body
		new E.FuncDef @pos, [], body


	func: (tokens) ->
		[ before, last ] =
			tokens.allButAndLast()

		check T.curlied last

		args =
			before.map (token) => @local token
		body =
			@locals.withLocals args, =>
				@block last.body

		new E.FuncDef @pos, args, body


	local: (name) ->
		check (T.normalName name), ->
			"Expected local name, not #{name}"

		new E.Local name

	use: (tokens) ->
		check tokens.length == 1, ->
			"Did not expect anything after use at #{@pos}"
		u = new E.Use tokens[0]
		@locals.addLocal u.local
		u

	defLocal: (tokens) ->
		check tokens.length == 2, ->
			"Expected name, curlied after defLocal at #{@pos}"

		[ name, value ] = tokens

		@pos = value.pos

		val =
			if value.type == '|'
				# A local fun, eg . fun |arg
				@func value.body
			else
				@block value.body

		local = @local name

		@locals.addLocal local

		new E.DefLocal local, val



parse = (tokens, typeName) ->
	type tokens, Array
	type typeName, String
	(new Parser typeName).all tokens

module.exports = parse

