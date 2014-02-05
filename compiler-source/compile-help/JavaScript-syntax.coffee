{ type } = require '../help/✔'

# <developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Reserved_Words>
javaScriptKeywords =
	"""
	abstract
	arguments
	boolean
	break
	byte
	case
	catch
	char
	class
	comment
	const
	continue
	debugger
	default
	delete
	do
	double
	else
	enum
	eval
	export
	extends
	false
	final
	finally
	float
	for
	function
	goto
	if
	implements
	import
	in
	instanceOf
	int
	interface
	label
	long
	native
	new
	null
	package
	private
	protected
	public
	return
	require
	short
	static
	super
	switch
	synchronized
	this
	throw
	throws
	transient
	true
	try
	typeof
	var
	void
	while
	with
	""".split '\n'

legalJavaScriptNameChar =
	/[^a-zA-Z]/g

###
Generates a valid JavaScript local name from a Smith one.
These names use `_` as an escape character,
	which is why Smith local names can't contain `_`.
@return [String]
###
@mangle = (name) ->
	type name, String

	if name in javaScriptKeywords
		"_#{name}"
	else
		name.replace legalJavaScriptNameChar, (ch) ->
			"_#{ch.charCodeAt 0}"

###
A literal which, if quoted in JavaScript, would represent `str`.
@return [String]
###
@toStringLiteral = (str) ->
	type str, String

	escaped =
		str.replace /'|"|\t|\n/g, (char) ->
			switch char
				when '\n'
					'\\n'
				when '\t'
					'\\t'
				when "'"
					"\\'"

	"'#{escaped}'"
