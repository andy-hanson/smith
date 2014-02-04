{ type } = require './✔'

jsWords =
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


module.exports = (text) ->
	type text, String

	if text in jsWords
		"_#{text}"
	else
		text.replace /[^a-zA-Z0-9_]/g, (ch) ->
			"_#{ch.charCodeAt 0}_"

