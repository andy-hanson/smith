T = require './Token'
E = require './Expression'
Pos = require './Pos'
AllModules = require './AllModules'
Locals = require './Locals'
{ cCheck, cFail } = require './CompileError'

class Parser
	constructor: (@typeName, @fileName, @allModules) ->
		type @typeName, String
		type @fileName, String
		type @allModules, AllModules

		@locals =
			new Locals
		@pos =
			Pos.start

	###
	Returns: [ iz, fun ]
	###
	all: (tokens) ->
		autoUses = @autoUses()

		[ iz, bodyTokens ] = @readIs tokens # TODO: don't conflict with auto
		if iz?
			type iz, E.Use
			@locals.addLocalMayShadow iz.local

		fun = @argLessFun bodyTokens
		fun.body.subs = autoUses.concat fun.body.subs

		[ iz, fun ]

	autoUses: ->
		typeLocal =
			E.Local.eager new T.Name @pos, @typeName, 'x'
		@locals.addLocal typeLocal
		defTypeLocal =
			new E.DefLocal typeLocal, new E.Me @pos

		noUseMe =
			(@allModules.autoUses @fileName).filter (use) =>
				use.local.name != @typeName
		autoUses =
			noUseMe.map (use) =>
				@locals.addLocal use.local
				new E.DefLocal use.local, use

		autoUses.unshift defTypeLocal
		autoUses



	###
	Returns: [ iz, restOfTokens ]
	###
	readIs: (tokens) ->
		if T.is tokens[0]
			[ (new E.Use tokens[0], @fileName, @allModules), tokens.tail() ]
		else
			[ null, tokens ]

		###
		iz = null
		doesses = []

		for token, index in tokens
			continue if T.nl token
			if T.isOrDoes token
				if token.kind == 'is'
					use = new E.Use token, @fileName, @allModules
					iss = E.IsDoes use, 'is'
				else
					doesses.push E.IsDoes token, 'does'
			else
				break

		return [ iz, doesses, tokens.slice index ]
		###


	block: (tokens) ->
		type tokens, Array

		exprs =
			(tokens.splitBy T.nl).filter (toks) ->
				not toks.isEmpty()

		parsed =
			exprs.map (tokens) =>
				@expression tokens

		new E.Block @pos, parsed

	valueExpression: (tokens) ->
		@expression tokens, yes

	expression: (tokens, isValue = no) ->
		type tokens, Array
		type isValue, Boolean

		if tokens.isEmpty()
			return new E.Null @pos

		tok0 = tokens[0]

		if tok0 instanceof T.Use
			@use tokens, isValue
		else if tok0 instanceof T.Def
			cCheck not isValue, @pos,
				'Can not have local def in inner expression.'
			@def tok0, tokens
		else if T.defLocal tok0
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
								when '@x'
									new E.Property pop, tok0
								when '.x_'
									new E.BoundFunc slurped.pop(), tok0
								else
									fail()
						else if tok0.kind == '@x'
							@soloExpression tok0
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
			else if tail.isEmpty()
				e0
			else
				new E.Call.of e0, tail

	###
	Expression of a single token
	###
	soloExpression: (token) ->
		type token, T.Token

		@pos = token.pos

		unexpected = =>
			cFail @pos, "Unexpected #{token}"

		switch token.constructor
			when T.Name
				switch token.kind
					when 'x'
						@get token
					when '_x'
						new E.ItFunDef token
					when 'x_'
						new E.BoundFun.me token
					when '@x'
						E.Property.me @pos, token
					else
						unexpected token
			when T.Group
				switch token.kind
					when '|'
						@fun token.body
					when '('
						new E.Parend @valueExpression token.body
					when '['
						unexpected token
					when '{'
						@argLessFun token.body
					when '"'
						@quote token
					else
						unexpected token
			when T.Special
				switch token.kind
					when 'me'
						new E.Me token.pos
					when 'it'
						@locals.getIt()
					else
						unexpected token
			else
				if token instanceof T.Literal
					new E.Literal token
				else
					unexpected token

	quote: (quote) ->
		type quote, T.Group

		new E.Quote quote.pos, quote.body.map (part) =>
			@soloExpression part

	_accessLocalOr: (name, orElse) ->
		type name, T.Name
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
			cFail @pos, "Type #{name.text} must be a local (not in #{@locals})"

	containsIt: (x) ->
		if x instanceof Array
			x.containsWhere @bound 'containsIt'
		else
			type x, T.Token
			if x instanceof T.Group and not T.curlied x
				@containsIt x.body
			else if T.it x
				yes
			else
				no


	argLessFun: (body) ->
		args =
			if @containsIt body
				[ E.Local.it @pos ]
			else
				[ ]

		@locals.withLocals args, =>
			[ meta, body ] =
				@funBody body

			new E.FunDef @pos, meta, null, args, body

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
					when 'in', 'eg'
						getBlock()
					when 'out'
						@locals.withLocal (E.Local.res @pos), getBlock
					else
						fail()

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
		cCheck (T.normalName name), @pos, ->
			"Expected local name, not #{name}"

		type =
			if typeName?
				@getLocalOnly typeName
			else
				null

		E.Local.eager name, type

	use: (tokens, isValue) ->
		check tokens.length == 1, =>
			"Did not expect anything after use at #{@pos}"

		use =
			new E.Use tokens[0] , @fileName, @allModules

		if isValue
			cCheck use.kind == 'use', @pos,
				"Use as value must be of kind 'use'"
			use
		else
			cCheck use.kind != 'is', @pos, 'is must be at top of file'
			@locals.addLocalMayShadow use.local
			if use.kind == 'does'
				E.does use
			else
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

		check locals.length == 1

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


###
Returns: [ iz, fun ]
###
parse = (tokens, typeName, fileName, allModules) ->
	type tokens, Array
	type typeName, String
	type fileName, String
	type allModules, AllModules

	(new Parser typeName, fileName, allModules).all tokens

module.exports = parse

