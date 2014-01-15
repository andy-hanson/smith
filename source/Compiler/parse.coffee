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
	Returns: [ super, autoUses, fun ]
	###
	all: (tokens) ->
		autoUses = @autoUses()

		typeLocal =
			E.Local.eager new T.Name @pos, @typeName, 'x'

		useTypeLocal =
			new E.DefLocal typeLocal, E.Use.typeLocal @typeName, @fileName, @allModules

		[ meta, restTokens ] =
			@takeAllMeta tokens, [], useTypeLocal

		[ sooper, bodyTokens ] =
			@readSuper restTokens #TODO: don't conflict with auto
		if sooper?
			type sooper, E.Use
			@locals.addLocalMayShadow sooper.local

		body =
			@locals.withLocal typeLocal, =>
				@block bodyTokens

		thisTypeLocal =
			new E.DefLocal typeLocal, new E.Me @pos

		body.subs.unshift thisTypeLocal


		fun = E.FunDef.plain @pos, meta, [], body

		[ sooper, autoUses, fun ]

	autoUses: ->
		noUseMe =
			(@allModules.autoUses @fileName).filter (use) =>
				use.local.name != @typeName
		autoUses =
			noUseMe.map (use) =>
				@locals.addLocal use.local
				new E.DefLocal use.local, use

		autoUses

	###
	Returns: [ super, restOfTokens ]
	###
	readSuper: (tokens) ->
		if T.super tokens[0]
			[ (new E.Use tokens[0], @fileName, @allModules), tokens.tail() ]
		else
			[ null, tokens ]

	block: (tokens) ->
		type tokens, Array

		exprs =
			(tokens.splitBy T.nl).filter (toks) ->
				not toks.isEmpty()

		parsed =
			exprs.map (tokens) =>
				@expression tokens

		new E.Block @pos, parsed

	unexpected: (token) ->
		cFail @pos, "Unexpected #{token}"

	valueExpression: (tokens) ->
		@expression tokens, yes

	expression: (tokens, isValue = no) ->
		type tokens, Array
		type isValue, Boolean

		[ parts, opts ] = @expressionParts tokens, isValue

		if parts.isEmpty()
			cCheck opts.isEmpty, @pos,
				'Unexpected options'
			new E.Null @pos
		else
			[ e0, tail ] = parts.unCons()

			if e0 instanceof E.Call
				unless tail.isEmpty()
					check e0.args.isEmpty()
					e0.args = tail
				e0.optionArgs = opts
				e0
			else if e0 instanceof E.ManyArgs
				@unexpected e0
			else if tail.isEmpty()
				e0
			else
				new E.Call.of e0, opts, tail

	###
	Returns [regularParts, optionParts]
	###
	expressionParts: (tokens, isValue) ->
		type tokens, Array
		type isValue, Boolean

		tok0 = tokens[0]

		plain = (x) ->
			[ [x], [] ]

		if tok0 instanceof T.Use
			plain @use tokens, isValue
		else if tok0 instanceof T.Def
			cCheck not isValue, @pos,
				'Can not have local def in inner expression.'
			plain @def tok0, tokens
		else if T.defLocal tok0
			plain @defLocal tokens.tail(), tok0.kind == '∘'
		else
			###
			1.~= 2 [5]
			###

			slurped = []
			opts = []

			# TODO: tokens.forEach
			until tokens.isEmpty()
				tok0 = tokens[0]
				tokens = tokens.tail()
				x =
					if T.dotLikeName tok0
						pop = slurped.pop()
						if pop?
							switch tok0.kind
								when '.x'
									new E.Call.noArgs pop, tok0
								when '@x'
									new E.Property pop, tok0
								when '.x_'
									new E.BoundFun pop, tok0
								else
									fail()
						else if tok0.kind == '@x'
							@soloExpression tok0
						else
							@unexpected tok0
					else if T.square tok0
						@pos = tok0.pos
						[ someOpts, optOpts ] = @expressionParts tok0.body, yes
						cCheck optOpts.isEmpty(),
							'Did not expect options within options'
						opts.pushAll someOpts
						null
					else if T.ellipsisName tok0
						new E.ManyArgs @get tok0
					else
						@soloExpression tok0

				if x?
					type x, E.Expression
					slurped.push x

			[ slurped, opts ]


	###
	Expression of a single token
	###
	soloExpression: (token) ->
		type token, T.Token

		@pos = token.pos
		type @pos, Pos

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
						@unexpected token
			when T.Group
				switch token.kind
					when '|'
						@fun token.body
					when '('
						new E.Parend @valueExpression token.body
					when '['
						@unexpected token
					when '{'
						@fun [ token ]
					when '"'
						@quote token
					else
						@unexpected token
			when T.Special
				switch token.kind
					when 'me'
						new E.Me token.pos
					when 'it'
						@locals.getIt @pos
					else
						@unexpected token
			else
				if token instanceof T.Literal
					new E.Literal token
				else
					@unexpected token

	quote: (quote) ->
		if quote instanceof T.Group
			# every part is a string literal or () group
			new E.Quote quote.pos, quote.body.map @bound 'soloExpression'
		else
			new E.Literal quote

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

	fun: (tokens) ->
		type tokens, Array

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

		[ optArgs, optRest, restArgsTokens ] =
			@takeOptionalArguments argsTokens
		[ args, maybeRest ] =
			@takeNewLocals restArgsTokens

		[ meta, body ] =
			if T.curlied last
				bodyTokens = last.body

				if argsTokens.isEmpty() and @containsIt bodyTokens
					args = [ E.Local.it @pos ]

				newLocals = args.slice()
				if optArgs?
					newLocals.pushAll optArgs
				if optRest?
					newLocals.push optRest
				newLocals.push maybeRest if maybeRest?

				@funBody bodyTokens, newLocals
			else
				[ (new E.Meta @pos), null ]

		new E.FunDef \
			@pos, meta, returnType, \
			optArgs, optRest, \
			args, maybeRest, body

	takeOptionalArguments: (tokens) ->
		if T.square tokens[0]
			[ optArgs, optRest ] =
				@takeNewLocals tokens[0].body
			[ optArgs, optRest, tokens.tail() ]
		else
			[ null, null, tokens ]

	###
	Returns [plainLocals, restLocal]
	###
	takeNewLocals: (tokens) ->
		out = []
		rest = null

		while not tokens.isEmpty()
			name = tokens[0]

			if T.ellipsisName name
				tokens = tokens.tail()
				cCheck tokens.isEmpty(), @pos, ->
					"Did not expect anything after ellipsis"
				rest = E.Local.eager name, null

			else if T.plainName name
				[ typeName, tokens ] =
					if T.typeName tokens[1]
						[ tokens[1], tokens.tail().tail() ]
					else
						[ null, tokens.tail() ]
				out.push @newLocal name, typeName
			else
				@unexpected name

		[out, rest]

	###
	Returns: [ Meta, bodyTokens ]
	###
	takeAllMeta: (tokens, newLocals = [], useTypeLocal) ->
		type tokens, Array
		type newLocals, Array
		[ metaToks, bodyToks ] =
			tokens.takeWhile (x) ->
				(T.nl x) or \
					x instanceof T.MetaText or \
					T.metaGroup x
		meta =
			new E.Meta @pos

		metaToks.forEach (tok) =>
			@meta meta, tok, newLocals, useTypeLocal

		[ meta, bodyToks ]

	###
	Returns: [ Meta, Block ]
	###
	funBody: (tokens, newLocals) ->
		[ meta, bodyTokens] =
			@takeAllMeta tokens, newLocals

		body =
			@locals.withLocals newLocals, =>
				@block bodyTokens

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

	meta: (meta, token, newLocals, useTypeLocal) ->
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
						@locals.withLocals newLocals, getBlock
					when 'eg'
						if useTypeLocal?
							x = @locals.withLocal useTypeLocal.local, getBlock
							x.subs.unshift useTypeLocal
							x
						else
							@locals.withFrame getBlock
					when 'out'
						@locals.withLocals newLocals, =>
							@locals.withLocal (E.Local.res @pos), getBlock
					else
						fail()

			else
				fail()

	# Local from function arg
	newLocal: (name, typeName) ->
		cCheck (T.plainName name), @pos, ->
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
			cCheck use.kind != 'super', @pos, 'is must be at top of file'
			@locals.addLocalMayShadow use.local
			if use.kind == 'trait'
				E.trait use
			else
				new E.DefLocal use.local, use

	defLocal: (tokens, lazy) ->
		type tokens, Array
		type lazy, Boolean
		##check tokens.length == 2, ->
		#	"Expected name, curlied after defLocal at #{@pos}"

		[ before, value ] =
			tokens.allButAndLast()

		[ locals, rest ] =
			@takeNewLocals before

		cCheck locals.length == 1, @pos, "Multiple assignments are TODO"
		cCheck rest == null, @pos, "Multiple assignments are TODO"

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
					@unexpected val

		@locals.addLocal local

		new E.DefLocal local, val


###
Returns: [ sooper, autoUses, fun ]
###
module.exports = (tokens, typeName, fileName, allModules) ->
	(new Parser typeName, fileName, allModules).all tokens
