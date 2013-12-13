T = require './Token'
E = require './Expression'
Pos = require './Pos'
AllModules = require './AllModules'
Locals = require './Locals'
{ cFail } = require './CompileError'

class Parser
	constructor: (@typeName, @fileName, @allModules) ->
		type @typeName, String
		type @fileName, String
		type @allModules, AllModules

		@locals =
			new Locals
		@pos =
			Pos.start

	all: (tokens) ->
		typeLocal =
			E.Local.eager new T.Name @pos, @typeName, 'x'
		@locals.addLocal typeLocal

		b = @block tokens
		b.subs.unshift new E.DefLocal typeLocal, new E.Me @pos
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
			return new E.Null @pos

		tok0 = tokens[0]

		if tok0 instanceof T.Use
			@use tokens
		else if tok0 instanceof T.Def
			@def tok0, tokens
		else if tok0 instanceof T.Special and ['∙', '∘'].contains tok0.kind
			@defLocal tokens.tail(), tok0.kind == '∘'
		else
			slurped = []
			until tokens.isEmpty()
				tok0 = tokens[0]
				x =
					if T.dotLikeName tok0
						tokens = tokens.tail()
						pop = slurped.pop()
						if pop?
							switch tok0.kind
								when '.x'
									new E.Call pop, tok0, []
								when ',x'
									new E.Property pop, tok0
								when '.x_'
									new E.BoundFunc slurped.pop(), tok0
								else
									fail()
						else
							fail "Unexpected #{tok0}"
					else
						tokens = tokens.tail()
						z = @soloExpression tok0

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
				switch t.kind
					when 'x'
						@get t
					when '_x'
						new E.ItFunDef t
					when 'x_'
						new E.BoundFun.me t
					else
						unexpected t
			when T.Group
				switch t.kind
					when '|'
						@fun t.body
					when '('
						new E.Parend @expression t.body
					when '['
						unexpected t
					when '{'
						@curlied t
					when '"'
						@quote t
					else
						unexpected t
			when T.Special
				switch t.kind
					when 'me'
						new E.Me t.pos
					else
						unexpected t
			else
				if t instanceof T.Literal
					new E.Literal t
				else
					unexpected t

	quote: (quote) ->
		type quote, T.Group

		new E.Quote quote.pos, quote.body.map (part) =>
			@soloExpression part

	_accessLocalOr: (name, orElse) ->
		local = @locals.get name
		if local?
			new E.LocalAccess @pos, local
		else
			orElse()

	get: (name) ->
		@_accessLocalOr name, ->
			E.Call.me name.pos, name.text, []

	getLocalOnly: (name) ->
		@_accessLocalOr name, =>
			cFail @pos, "Type #{name.text} must be a local"

	###
	TODO: 'it'
	###
	curlied: (curlied) ->
		[ meta, body ] =
			@funBody curlied.body
		new E.FunDef @pos, meta, null, [], body

	fun: (tokens) ->
		lastToken = tokens.last()

		[ before, last ] =
			if T.curlied lastToken
				tokens.allButAndLast()
			else
				[ tokens, null ]
		[ returnType, argsTokens ] =
			if T.typeName before[0]
				[ (@get before[0]), before.tail() ]
			else
				[ null, before ]

		args =
			@takeNewLocals argsTokens
		[ meta, body ] =
			if T.curlied last
				@locals.withLocals args, =>
					@funBody last.body
			else
				[ (new E.Meta @pos), null ]

		new E.FunDef @pos, meta, returnType, args, body

	###
	Returns: [Meta, Block]
	###
	funBody: (tokens) ->
		type tokens, Array

		[ metaToks, restToks ] =
			tokens.takeWhile (x) ->
				(T.nl x) or \
					x instanceof T.MetaText or \
					T.metaGroup x

		meta =
			new E.Meta @pos

		metaToks.forEach (tok) =>
			@meta meta, tok

		body =
			@block restToks

		[ meta, body ]

	###
	Eg: ‣deffer def-name arg1 arg2
	###
	def: (def, tokens) ->
		type def, T.Def
		type tokens, Array

		if tokens.isEmpty()
			fail "Expected something after #{def}"

		check tokens[0] instanceof T.Def

		fun =
			@fun tokens.tail()
		args =
			[ (new E.Literal new T.StringLiteral @pos, def.name2), fun ]

		E.Call.me @pos, def.name, args

	meta: (meta, token) ->
		return if T.nl token

		meta[token.kind] =
			if token instanceof T.MetaText
				@quote token.text
			else if T.metaGroup token
				check token.body.length == 1
				curlied = token.body[0]
				check T.curlied curlied

				getBlock = =>
					@block curlied.body

				switch token.kind
					when 'in', 'out'
						getBlock()
					when 'out'
						@locals.withLocal (E.Local.res @pos), getBlock

			else
				fail()

	takeNewLocals: (tokens) ->
		out = []

		while not tokens.isEmpty()
			name = tokens[0]
			[ typeName, tokens ] =
				if T.typeName tokens[1]
					[ tokens[1], tokens.tail().tail() ]
				else
					[ null, tokens.tail() ]

			out.push @newLocal name, typeName, no

		out

	# Local from function arg
	newLocal: (name, typeName) ->
		check (T.normalName name), ->
			"Expected local name, not #{name}"

		type =
			if typeName?
				@getLocalOnly typeName
			else
				null

		E.Local.eager name, type

	use: (tokens) ->
		check tokens.length == 1, =>
			"Did not expect anything after use at #{@pos}"

		use =
			new E.Use tokens[0], @fileName, @allModules
		@locals.addLocal use.local
		new E.DefLocal use.local, use

	defLocal: (tokens, lazy) ->
		type tokens, Array
		type lazy, Boolean
		##check tokens.length == 2, ->
		#	"Expected name, curlied after defLocal at #{@pos}"

		[ before, value ] =
			tokens.allButAndLast()

		locals =
			@takeNewLocals before

		check locals.length == 1 #TODO: array extraction
		local = locals[0]
		local.lazy = lazy

		@pos = value.pos

		type value, T.Group

		val =
			switch value.kind
				when '|'
					# A local fun, eg . fun |arg
					check not lazy, =>
						"[#{@pos}] must use ∙ before local fun, not ∘"
					@fun value.body
				when '{'
					@block value.body
				else
					throw new Error "Unexpected value #{val}"

		@locals.addLocal local

		new E.DefLocal local, val



parse = (tokens, typeName, fileName, allModules) ->
	type tokens, Array
	type typeName, String
	type fileName, String
	type allModules, AllModules
	(new Parser typeName, fileName, allModules).all tokens

module.exports = parse

