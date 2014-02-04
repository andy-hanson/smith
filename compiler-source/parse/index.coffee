T = require '../Token'
E = require '../Expression'
Pos = require '../compile-help/Pos'
AllModules = require '../compile/AllModules'
{ cCheck, cFail } = require '../compile-help/✔'
{ check, type, typeExist } =  require '../help/✔'
Options = require '../run/Options'
{ containsWhere, isEmpty, last, rightUnCons,
	split, splitOnceWhere, tail, unCons } = require '../help/list'
Locals = require './Locals'

class Parser
	constructor: (@typeName, @fileName, @options) ->
		type @typeName, String, @fileName, String, @options, Options

		@locals =
			new Locals
		@pos =
			Pos.start

	###
	Returns: [ superAccess, autoUses, fun ]
	###
	all: (tokens) ->
		autoUses = @autoUses()

		typeLocal =
			E.Local.eager new T.Name @pos, @typeName, 'x'

		useTypeLocal =
			new E.DefLocal typeLocal, E.Use.typeLocal @typeName, @fileName, @options.allModules()

		[ meta, restTokens ] =
			@takeAllMeta tokens, [], useTypeLocal

		[ sooper, bodyTokens ] =
			@readSuper restTokens #TODO: don't conflict with auto
		superAccess =
			if sooper?
				type sooper, E.Use
				@locals.addLocalMayShadow sooper.local
				sooper
				#new E.LocalAccess Pos.start, sooper.local
			else
				new E.Null Pos.start, 0

		#if sooper?
		#	autoUses.push sooper

		body =
			@locals.withLocal typeLocal, =>
				@block bodyTokens

		if sooper?
			body.subs.unshift E.DefLocal.fromUse sooper

		thisTypeLocal =
			new E.DefLocal typeLocal, new E.Me @pos

		body.subs.unshift thisTypeLocal


		fun = E.FunDef.plain @pos, meta, [], body

		[ superAccess, autoUses, fun ]

	autoUses: ->
		noUseMe =
			(@options.allModules().autoUses @fileName).filter (use) =>
				use.local.name != @typeName
		autoUses =
			noUseMe.map (use) =>
				@locals.addLocal use.local
				new E.DefLocal.fromUse use

		autoUses

	###
	Returns: [ super, restOfTokens ]
	###
	readSuper: (tokens) ->
		if T.super tokens[0]
			[ (new E.Use tokens[0], @fileName, @options.allModules()), (tail tokens) ]
		else
			[ null, tokens ]

	block: (tokens) ->
		type tokens, Array

		exprs =
			(split tokens, T.nl).filter (toks) ->
				not isEmpty toks

		parsed =
			exprs.map (tokens) =>
				@expression tokens

		new E.Block @pos, parsed

	unexpected: (token) ->
		cFail @pos, "Unexpected #{token}"

	valueExpression: (tokens) ->
		@expression tokens, yes

	###
	isValue is whether the expression *must* be a value.
	Use expressions in parentheses must be values.
	###
	expression: (tokens, isValue = no) ->
		type tokens, Array, isValue, Boolean

		parts = @expressionParts tokens, isValue

		if isEmpty parts
			new E.Null @pos
		else
			[ e0, rest ] = unCons parts

			if e0 instanceof E.Call
				unless isEmpty rest
					check isEmpty e0.args
					e0.args = rest
				e0
			else if e0 instanceof E.ManyArgs
				@unexpected e0
			else if isEmpty rest
				e0
			else
				new E.Call.of e0, rest


	expressionParts: (tokens, isValue) ->
		type tokens, Array, isValue, Boolean

		token = tokens[0]

		plain = (x) ->
			[ x ]

		if token instanceof T.Use
			plain @use tokens, isValue
		else if token instanceof T.Def
			cCheck not isValue, @pos,
				'Can not have local def in inner expression.'
			plain @def token, tokens
		else if T.defLocal token
			plain @defLocal (tail tokens), token.kind == '∘'
		else
			slurped = []

			tokens.forEach (token) =>
				x =
					if T.dotLikeName token
						pop = slurped.pop()
						if pop?
							switch token.kind
								when '.x'
									new E.Call.noArgs pop, token
								when '@x'
									new E.PropertyAccess pop, token
								when '.x_'
									new E.BoundFun pop, token
								else
									fail()
						else if token.kind == '@x'
							@soloExpression token
						else
							@unexpected token
					else if T.ellipsisName token
						new E.ManyArgs @get token
					else
						@soloExpression token

				if x?
					type x, E.Expression
					slurped.push x
				else
					fail() # this never happens, right?

			slurped


	###
	Expression of a single token
	###
	soloExpression: (token) ->
		@pos = token.pos
		type token, T.Token, @pos, Pos

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
						E.PropertyAccess.me @pos, token
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
					when '→'
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
			new E.Quote quote.pos, quote.body.map (litOrGroup) =>
				@soloExpression litOrGroup
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

	checkPlainName: (name) ->
		cCheck (T.plainName name), @pos, ->
			"Expected local name, not #{name}"

	getLocalOnly: (name) ->
		###
		Can only be a local, not a method.
		###
		@_accessLocalOr name, =>
			cFail @pos, "Type #{name.text} must be a local (not in #{@locals})"

	containsIt: (x) ->
		if x instanceof Array
			containsWhere x, (sub) =>
				@containsIt sub
		else
			type x, T.Token
			if x instanceof T.Group and not T.indented x
				@containsIt x.body
			else if T.it x
				yes
			else
				no

	fun: (tokens) ->
		type tokens, Array

		lastToken = last tokens

		[ before, bodyGroup ] =
			if T.indented lastToken
				rightUnCons tokens
			else
				[ tokens, null ]

		[ returnType, argsTokens ] =
			if T.typeName before[0]
				[ (@get before[0]), (tail before) ]
			else
				[ null, before ]

		[ args, maybeRest ] =
			@takeNewLocals argsTokens

		[ meta, body ] =
			if bodyGroup?
				bodyTokens = bodyGroup.body

				if (isEmpty argsTokens) and @containsIt bodyTokens
					args = [ E.Local.it @pos ]

				newLocals = args.slice()
				newLocals.push maybeRest if maybeRest?

				@funBody bodyTokens, newLocals
			else
				[ (new E.Meta @pos), null ]

		new E.FunDef @pos, meta, returnType, args, maybeRest, body

	###
	Returns [plainLocals, restLocal]
	###
	takeNewLocals: (tokens) ->
		type tokens, Array

		out = []
		rest = null

		index = 0
		while index < tokens.length
			name = tokens[index]
			type name, T.Token
			index += 1

			if T.ellipsisName name
				cCheck index == tokens.length, @pos, ->
					"Did not expect anything after ellipsis"
				rest = E.Local.eager name, null

			else if T.plainName name
				typeName =
					if T.typeName tokens[index]
						index += 1
						tokens[index - 1]
					else
						null
				out.push @newLocal name, typeName
			else
				@unexpected name

		[out, rest]

	###
	Returns: [ Meta, bodyTokens ]
	###
	takeAllMeta: (tokens, newLocals = [], useTypeLocal) ->
		type tokens, Array, newLocals, Array
		typeExist useTypeLocal, E.DefLocal

		[ metaToks, bodyToks ] =
			splitOnceWhere tokens, (x) ->
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
		type def, T.Def, tokens, Array

		check not (isEmpty tokens), "Expected something after #{def}"

		check tokens[0] instanceof T.Def

		fun =
			@fun tail tokens
		args =
			[ (new E.Literal new T.StringLiteral @pos, def.name2), fun ]

		E.Call.me @pos, def.name, args

	meta: (meta, token, newLocals, useTypeLocal) ->
		type meta, E.Meta, newLocals, Array
		typeExist useTypeLocal, E.DefLocal

		return if T.nl token

		meta[token.kind] =
			if token instanceof T.MetaText
				@quote token.text
			else if T.metaGroup token
				check token.body.length == 1
				indented = token.body[0]
				check T.indented indented

				getBlock = =>
					@block indented.body

				switch token.kind
					when 'in'
						@locals.withLocals newLocals, getBlock
					when 'eg', 'sub-eg'
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
		@checkPlainName name

		localType =
			if typeName?
				@getLocalOnly typeName
			else
				null

		E.Local.eager name, localType

	use: (tokens, isValue) ->
		check tokens.length == 1, =>
			"Did not expect anything after use at #{@pos}"

		use =
			new E.Use tokens[0] , @fileName, @options.allModules()

		if isValue
			cCheck use.kind == 'use', @pos,
				"Use as value must be of kind 'use'"
			use.local.isUsed()
			use

		else
			cCheck use.kind != 'super', @pos, 'super must be at top of file'
			@locals.addLocalMayShadow use.local
			if use.kind == 'trait'
				new E.Trait use
			else
				new E.DefLocal.fromUse use

	defLocal: (tokens, lazy) ->
		type tokens, Array, lazy, Boolean
		[ before, value ] =
			rightUnCons tokens

		type value, T.Group

		[ locals, rest ] =
			@takeNewLocals before

		cCheck locals.length == 1, @pos, "Multiple assignments are TODO"
		cCheck rest == null, @pos, "Multiple assignments are TODO"

		local = locals[0]
		local.lazy = lazy

		@pos = value.pos

		val =
			switch value.kind
				when '|'
					# A local fun, eg . fun |arg
					check not lazy, =>
						"[#{@pos}] must use ∙ before local fun, not ∘"
					@fun value.body
				when '→'
					@block value.body
				else
					@unexpected val

		@locals.addLocal local

		new E.DefLocal local, val


###
Returns: [ sooperAccess, autoUses, fun ]
###
module.exports = (tokens, typeName, fileName, options) ->
	(new Parser typeName, fileName, options).all tokens
