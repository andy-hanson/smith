{ check, type } =  require '../help/✔'
{ read } = require '../help/meta'
{ repeated } = require '../help/str'
Options = require '../run/Options'

###
Represents the context of compiling an Expression.

@method #options()
  @return [Options]
@method #fileName()
  @return [String]
@method #indent()
  The indent used at this part in the output code.
  @return [String]
###
module.exports = class Context
	# Constructs from options, file name, and indent string.
	constructor: (@_options, @_fileName, @_indent) ->
		type @_options, Options, @_fileName, String, @_indent, String

	read @, 'options', 'fileName', 'indent'

	###
	A new Context with `@indent()` containing `n` more tabs.
	###
	indented: (n = 1) ->
		check n > 0
		new Context @options(), @fileName(), "#{repeated '\t', n}#{@indent()}"