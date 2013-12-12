jsWords =
	"""
	abstract
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
	if jsWords.contains text
		"_#{text}"
	else
		parts =
			text.map (ch) ->
				if ch.match /[a-zA-Z0-9_]/
					ch
				else
					"$#{ch.charCodeAt 0}$"

		parts.join ''

