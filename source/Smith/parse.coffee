T = require './Token'
E = require './Expression'
Pos = require './Pos'
AllModules = require './AllModules'

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


class Parser
	constructor: (@typeName, @fileName, @allModules) ->
		type @typeName, String
		type @fileName, String
		type @allModules, AllModules

		@locals =
			new Locals
		@pos =
			Pos.start
		@_canAccessThis = yes

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
			return new E.Void @pos

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
					when 'arguments'
						new E.Arguments t.pos
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

	get: (name) ->
		type name, T.Name

		local = @locals.get name
		if local?
			new E.LocalAccess @pos, local
		else if @_canAccessThis
			E.Call.me name.pos, name.text, []
		else
			throw new Error "Cannot access 'this' inside eg at #{@pos}"

	###
	TODO: 'it'
	###
	curlied: (curlied) ->
		[ meta, body ] =
			@funBody curlied.body
		new E.FunDef @pos, meta, null, [], body

	fun: (tokens) ->
		[ before, last ] =
			if T.curlied tokens.last()
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
			if last?
				@locals.withLocals args, =>
					@funBody last.body
			else
				[ (new E.Meta @pos), null ]

		new E.FunDef @pos, meta, returnType, args, body

	###
	Returns: [Meta, Block]
	###
	funBody: (tokens) ->
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

	withoutThisAccess: (fun) ->
		@_canAccessThis = no
		val = fun()
		@_canAccessThis = yes
		val

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
					when 'in'
						getBlock()
					when 'out'
						@locals.withLocal (E.Local.res @pos), getBlock
					when 'eg'
						@withoutThisAccess getBlock

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
				@get typeName
			else
				null

		E.Local.eager name, type

	use: (tokens) ->
		check tokens.length == 1, =>
			"Did not expect anything after use at #{@pos}"
		use =
			new E.Use tokens[0], @fileName, @allModules
		@locals.addLocal use.local
		use

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

