T = require '../Token'
E = require '../Expression'
Pos = require '../compile-help/Pos'
AllModules = require '../compile/AllModules'
{ cCheck, cFail } = require '../compile-help/✔'
{ check, fail, type, typeExist } =  require '../help/✔'
Options = require '../run/Options'
{ containsWhere, isEmpty, last, rightUnCons,
	splitWhere, tail, takeAndAfter, unCons } = require '../help/list'
Locals = require './Locals'

###
Converts a list of `Token`s to an `Expression`.
@private
###
class Parser
	###
	Arguments are the same as in `parse`.
	###
	constructor: (@typeName, @fileName, @options, @allModules) ->
		@locals =
			new Locals
		@pos =
			Pos.start()

	###
	Get a local or me-call named `name`.
	###
	access: (name, mustBeLocal = no) ->
		type name, T.Name
		if @locals.has name
			new E.AccessLocal @pos, @locals.get name
		else
			cCheck not mustBeLocal, @pos, 'Type #{name.text} must be a local'
			E.Call.me name.pos, name.text, [ ]

	###
	Get a local named `name`, or fail.
	###
	accessLocal: (name) ->
		@access name, yes

	###
	Returns same as `parse`.
	###
	all: (tokens) ->
		typeLocal =
			new E.Local new T.Name @pos, @typeName, 'x'
		useTypeLocal =
			new E.DefLocal typeLocal, E.Use.typeLocal @typeName, @fileName, @allModules
		autoUses =
			@autoUses()
		autoUses.forEach (use) =>
			@locals.addLocal use.local
		[ meta, restTokens ] =
			@takeMeta tokens, [ ], useTypeLocal
		[ sooper, bodyTokens ] =
			@readSuper restTokens #TODO: don't conflict with auto
		superAccess =
			if sooper?
				type sooper, E.Use
				@locals.addLocalMayShadow sooper.local
				sooper
			else
				new E.Null Pos.start()
		body =
			@locals.withLocal typeLocal, =>
				@block bodyTokens
		if sooper?
			body.subs.unshift E.DefLocal.fromUse sooper
		thisTypeLocal =
			new E.DefLocal typeLocal, new E.Me @pos
		body.subs.unshift thisTypeLocal
		fun =
			E.FunDef.plain @pos, meta, [ ], body
		[ superAccess, autoUses, fun ]

	###
	All `use` statements automatically added due to
		an `auto` declaration in a `modules` file.
	This type is not automatically used even if it is in `auto`,
		because that would be a cycle of `require`s.
	See `thisTypeLocal` in `all` for that.
	@return [Array<DefLocal>]
	###
	autoUses: ->
		noUseMe =
			(@allModules.autoUses @fileName).filter (use) =>
				use.local.name != @typeName
		noUseMe.map (use) ->
			new E.DefLocal.fromUse use

	###
	Parse the contents of a block.
	@return [E.Block]
	###
	block: (tokens) ->
		# newlines before '|' and '.' where removed during lexing.
		lines =
			(splitWhere tokens, T.nl).filter (line) ->
				not isEmpty line
		subs =
			lines.map (line) =>
				@expression line

		new E.Block @pos, subs

	###
	Whether `phrase` contains `it`.
	Sub-phrases that are themselves indented blocks are not counted.
	###
	containsIt: (phrase) ->
		type phrase, Array
		containsWhere phrase, (sub) =>
			type sub, T.Token
			if sub instanceof T.Group
				(not T.indented sub) and @containsIt sub.body
			else
				T.it sub

	###
	Define a local val or local fun.
	Also adds it to @locals.
	###
	defLocal: (tokens, lazy) ->
		type tokens, Array, lazy, Boolean
		[ before, value ] =
			rightUnCons tokens
		[ locals, rest ] =
			@takeNewLocals before

		cCheck locals.length == 1 and rest == null, @pos, 'TODO: Multiple assignments'
		local = locals[0]
		local.lazy = lazy

		@pos = value.pos

		val =
			switch value.kind
				when '|'
					# A local fun, eg . fun |arg
					cCheck not lazy, @pos, 'Local fun can not be lazy'
					@fun value.body
				when '→'
					@block value.body
				else
					@unexpected value

		@locals.addLocal local
		new E.DefLocal local, val


	###
	A single expression.
	@param isValue [Boolean]
	  Whether the expression must be a value, and not a local def.
	  Expressions in parentheses must be values.
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

	###
	Gets the arguments of a call.
	`a b.c d` has 2 arguments: `b.c` and `d`.
	@return [Array<Token>]
	###
	expressionParts: (tokens, isValue) ->
		type tokens, Array, isValue, Boolean

		token = tokens[0]

		plain = (x) ->
			[ x ]

		if token instanceof T.Use
			plain @use tokens, isValue
		else if token instanceof T.Def
			plain E.Call.def @pos, token, @fun tail tokens
		else if T.defLocal token
			cCheck not isValue, @pos,
				'Can not have local def in inner expression.'
			plain @defLocal (tail tokens), token.kind == '∘'
		else
			slurped = [ ]

			tokens.forEach (token) =>
				part =
					if T.dotLikeName token
						pop = slurped.pop()
						if pop?
							switch token.kind
								when '.x'
									new E.Call.noArgs pop, token
								when '@x'
									new E.AccessProperty pop, token
								when '.x_'
									new E.BoundFun pop, token
								else
									fail()
						else if token.kind == '@x'
							@soloExpression token
						else
							@unexpected token
					else if T.ellipsisName token
						new E.ManyArgs @access token
					else
						@soloExpression token

				slurped.push part

			slurped

	###
	Parses a fun (including the header).
	###
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
				[ (@accessLocal before[0]), (tail before) ]
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
	Parses the meta and body of a fun.
	@return [(Meta, Block)]
	###
	funBody: (tokens, newLocals) ->
		[ meta, bodyTokens] =
			@takeMeta tokens, newLocals

		body =
			@locals.withLocals newLocals, =>
				@block bodyTokens

		[ meta, body ]

	###
	Parse a `"` group.
	###
	quote: (quote) ->
		if quote instanceof T.Group
			# every part is a string literal or () group
			new E.Quote quote.pos, quote.body.map (litOrGroup) =>
				@soloExpression litOrGroup
		else
			type quote, T.StringLiteral
			new E.Literal quote


	###
	If possible, read in this type's `super`.
	@return [ (Use?, Array ]
	  (super, restOfTokens)
	###
	readSuper: (tokens) ->
		if T.super tokens[0]
			[ (new E.Use tokens[0], @fileName, @allModules), (tail tokens) ]
		else
			[ null, tokens ]

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
						@access token
					when '_x'
						new E.ItFunDef token
					when 'x_'
						new E.BoundFun.me token
					when '@x'
						E.AccessProperty.me @pos, token
					else
						@unexpected token
			when T.Group
				switch token.kind
					when '|'
						@fun token.body
					when '('
						new E.Parend @expression token.body, yes
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

	###
	Takes a fun's Meta.
	@return [(Meta, Array<Token>]
	  The Meta and remaining tokens.
	###
	takeMeta: (tokens, newLocals = [ ], useTypeLocal) ->
		type tokens, Array, newLocals, Array
		typeExist useTypeLocal, E.DefLocal

		meta =
			new E.Meta @pos

		index = 0
		while true
			token = tokens[index]
			index += 1

			if token instanceof T.MetaText
				meta[token.kind] = @quote token.text
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
			else if T.nl token
				continue
			else
				return [ meta, tokens.slice index - 1 ]

	###
	Looks like `a` or `a:Class`
	###
	takeNewLocal: (name, typeName) ->
		cCheck (T.plainName name), @pos, ->
			"Expected local name, not #{name}"

		localType =
			if typeName?
				@accessLocal typeName
			else
				null

		new E.Local name, localType

	###
	@return [(Array, E.Local?)]
	  List of normal locals, and maybe a rest argument.
	###
	takeNewLocals: (tokens) ->
		type tokens, Array

		out = [ ]
		rest = null

		index = 0
		while index < tokens.length
			name = tokens[index]
			type name, T.Token

			if T.ellipsisName name
				cCheck index == tokens.length - 1, @pos, 'Expected nothing after ellipsis'
				rest =
					new E.Local name, null

			else if T.plainName name
				typeName =
					if T.typeName tokens[index + 1]
						index += 1
						tokens[index]
					else
						null

				out.push @takeNewLocal name, typeName

			else
				@unexpected name

			index += 1

		[ out, rest ]

	###
	Fail because `token` is in the wrong place.
	###
	unexpected: (token) ->
		cFail @pos, "Unexpected #{token}"

	###
	A use expression.
	If `isValue`, just the value.
	Otherwise, a local def.
	###
	use: (tokens, isValue) ->
		check tokens.length == 1, =>
			"Did not expect anything after use at #{@pos}"

		use =
			new E.Use tokens[0] , @fileName, @allModules

		if isValue
			cCheck use.kind == 'use', @pos, 'Use as value must be of kind `use`.'
			use.local.isUsed()
			use

		else
			cCheck use.kind != 'super', @pos, '`super` must be at top of file.'
			@locals.addLocalMayShadow use.local
			if use.kind == 'trait'
				new E.Trait use
			else
				new E.DefLocal.fromUse use


###
@param tokens [Array]
  Tokenized source file.
@param typeName [String]
  Name of the file's type. ('Cool.smith' has typeName 'Cool')
@param fileName [String]
  Full name of the file.
@param options [Options]
@param allModules [AllModules]
@return [(Expression, Array<DefLocal>, FunDef)]
  (superAccess, autoUses, fun)
###
module.exports = parse = (tokens, typeName, fileName, options, allModules) ->
	type tokens, Array, typeName, String, fileName, String,
		options, Options, allModules, AllModules
	(new Parser typeName, fileName, options, allModules).all tokens
