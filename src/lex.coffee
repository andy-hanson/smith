Stream = require './Stream'
T = require './Token'

###
Left to lex:
1.23
###

keywords = ['use', 'arguments']

class GroupPre extends T.Token
	constructor: (@pos, @char) ->
	show: -> @char

checkSpaces = (str) ->
	for line, lineNumber in str.split '\n'
		if line.startsWith ' '
			throw new Error "Line #{lineNumber + 1} starts with a space."
		if line.endsWith ' '
			throw new Error "Line #{lineNumber + 1} ends with a space."

escape =
	't': '\t'
	'n': '\n'

###
TODO: \
###
lexQuote = (quoteType, stream, oldIndent) ->
	type quoteType, String
	type stream, Stream
	type oldIndent, Number

	read = ''
	out = []
	startPos = stream.pos

	indented = stream.peek() == '\n'
	quoteIndent = oldIndent + 1

	finish = ->
		lit = new T.StringLiteral stream.pos, read
		if quoteType == "'"
			lit
		else
			out.push lit
			new T.Group startPos, stream.pos, '"', '"', out

	loop
		ch = stream.readChar()

		if ch == undefined
			throw new Error "Unclosed quote starting at #{startPos}"

		else if ch == '\\'
			next = stream.readChar()
			read += (escape[next] or next)

		else if ch == '{' and quoteType == '"'
			out.push new T.StringLiteral stream.pos, read
			read = ''
			startPos =
				stream.pos
			interpolated =
				lexPlain stream, yes
			out.push new T.Group startPos, stream.pos, '(', ')', interpolated

		else if ch == '\n'
			unless indented
				throw new Error "Quote at #{startPos} not closed."
			# Read an indented section.
			nowIndent = (stream.takeMatching /\t/).length
			if nowIndent < quoteIndent
				return finish()
			else
				read += '\n' + (nowIndent - quoteIndent).repeat '\t'

		else if ch == quoteType and not indented
			return finish()

		else
			read += ch



lexPlain = (stream, inQuote) ->
	type stream, Stream

	out = []

	removePrecedingNL = ->
		if T.nl out.last()
			# No \n precedes '|' or '.x'
			out.pop()




	#nameChar = /[a-zA-Z!$%^&*\-+=<>?\/0-9‣]/
	# not space, not bracket, not punc, not quote, not comment, not bar, not JS literal, not @, not ∙
	notNameChar = /[\s\(\[\{\)\]\}\.;,'"#\|`@∙]/
	digit = /[0-9]/
	numChar = /[0-9]/

	indent = 0

	takeName = ->
		name = stream.takeNotMatching notNameChar
		if name.isEmpty()
			throw new Error "Expected name at #{pos}, got nothing"
		name

	while ch = stream.peek()
		pos = stream.pos

		if inQuote and ch == '}'
			stream.readChar()
			return out

		token =
			if ch.match /[\(\[\{\)\]\}]/
				stream.readChar()
				#return new T.Group startPos, pos, open, ch, out
				new GroupPre stream.pos, ch
			#if ch.match /[\(\[\{]/
			#	stream.readChar()
			#	lexPlain stream, ch

			else if ch.match digit
				n = stream.takeMatching numChar
				new T.NumberLiteral pos, n

			else if ch == '_'
				stream.readChar()
				name = takeName()
				new T.Name pos, name, '_x'

			else unless ch.match notNameChar
				name = takeName()
				if stream.peek() == '_'
					stream.readChar()
					new T.Name pos, name, 'x_'
				else if name in keywords
					if name == 'use'
						stream.takeMatching /\s/
						used = stream.takeNotMatching /\n/
						new T.Use pos, used
					else
						new T.Special pos, name
				else
					new T.Name pos, name, 'x'

			else if ch == '.'
				stream.readChar()
				name = takeName()
				removePrecedingNL()
				if stream.peek() == '_'
					stream.readChar()
					new T.Name pos, name, '.x_'
				else
					new T.Name pos, name, '.x'

			else if ch == "'"
				stream.readChar()
				name = takeName()
				new T.StringLiteral pos, name

			else if ch == '|'
				stream.readChar()
				removePrecedingNL()
				new GroupPre pos, ch

			else if ch == '∙'
				stream.readChar()
				new T.Special pos, ch

			else if ch == '`'
				stream.readChar()
				js = stream.takeNotMatching /`/
				stream.readChar()
				new T.JavascriptLiteral pos, js

			else if ch == ' '
				stream.takeMatching /\s/
				[]

			else if ch == '#'
				stream.readChar()
				next = stream.peek()

				if next == '{'
					stream.takeUpToString '}#'
					if stream.hasMore()
						stream.readChar()
						stream.readChar()
					else
						# Ate up whole file!
						# One final newline to close all indents.
						stream.str += '\n'

				else
					stream.takeUpToString '\n'
					check stream.peek() == '\n'
				[]

			else if ch == '\n'
				#check stream.prev() != ' ', ->
				#	new Error "Line ends in space at #{pos}"
				stream.takeMatching /\n/ #Skip through blank lines!
				old = indent
				now = (stream.takeMatching /\t/).length
				#check stream.peek() != ' ',
				#	new Error "Line begins with space at #{stream.pos}"
				indent = now
				if now == old
					removePrecedingNL()
					new T.Special pos, '\n'
				else if now < old
					x = (old - now).repeat new GroupPre stream.pos, '<-'
					x.push new T.Special stream.pos, '\n'
					x
				else if now == old + 1
					#lexPlain stream, '->'
					new GroupPre stream.pos, '->'
				else
					throw new Error \
						"#{pos} too indented! Was #{old}, now #{now}"

			else if ch == '"'
				stream.readChar()
				lexQuote ch, stream, indent

			else
				throw new Error \
					"Do not recognize char '#{stream.peek()}' at #{pos}"

		if token instanceof Array
			out.pushAll token
		else
			out.push token

	out



###
Remove any '\n' preceding a '|' or '.x'
Only one '\n' in a row
###
remove_some_newlines = (tokens) ->
	out = []
	onNewLines = no

	tokens.forEach (token) ->
		if onNewLines
			unless T.nl token
				unless T.bar token or T.dotLikeName token
					out.push onNewLines
				onNewLines = no
				out.push token
		else
			if T.nl token
				onNewLines = token
			else
				out.push token

	if onNewLines
		out.push onNewLines

	# Check it worked
	for token, idx in out
		if T.nl token
			next = out[idx + 1]
			if T.nl next
				fail 'Two \\n in a row'
			else if T.bar next or T.dotLikeName next
				fail '\\n precedes | or .x'
			else
				# yer OK

	if T.nl out[0]
		out.shift()
	out

joinGroups = (tokens) ->
	stack = []
	current = []
	opens = []

	new_level = (open) ->
		type open, GroupPre
		#console.log "push #{current}"
		opens.push open
		stack.push current
		current = []

	finish_level = (result) ->
		#console.log "pop #{result}"
		current = stack.pop()
		current.push result


	for tok in tokens
		if tok instanceof GroupPre
			ch = tok.char
			switch ch
				when '(', '[', '{', '->', '|'
					new_level tok
				when ')', ']', '}', '<-'
					if opens.isEmpty()
						throw new Error "Unexpected closing #{tok}"
					open = opens.pop()
					finish_level new T.Group \
						open.pos, tok.pos, open.char, ch, current

					if opens.last()?.char == '|'
						open = opens.pop()
						finish_level new T.Group \
							open.pos, tok.pos, open.char, '|', current

		else
			if tok instanceof T.Group # From Quotes
				tok.body = joinGroups tok.body
			current.push tok

	check opens.isEmpty(), ->
		new Error "Never closed " + opens.last()
	check stack.isEmpty()
	current

###
joinFunctions = (tokens) ->
	out = []
	bar = null
	f = []

	tokens.forEach (token) ->
		if T.bar token
			if bar?
				throw new Error "Did not expect #{token} after #{bar}"
			bar = token
			f = []
		else
			if bar?
				f.push token
				if T.curlied token
					out.push new T.Func bar, f
			else
				if T.curlied token
					out.push new T.Func null, [token]
				else
					out.push token

	if bar?
		throw new Error "Unfinished function starts at #{bar}"
###

###
TODO:
check all blank lines have no spaces
###
check_good = (str) ->
	yes

lex = (str) ->
	type str, String

	# final newline so indents will close
	#a = lexPlain stream, 'file-start'
	#b = remove_some_newlines a
	#c = join_groups b
	#d = join_functions c

	checkSpaces str

	str += '\n'
	stream = new Stream str
	plain = lexPlain stream
	tokens = joinGroups plain

	tokens.every (x) ->
		check x instanceof T.Token, ->
			"#{x} not a token"

	tokens


module.exports = lex
