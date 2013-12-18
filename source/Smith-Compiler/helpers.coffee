Object.prototype.bound = (name) ->
	@[name].bind @

Object.prototype.clone = ->
	x = { }
	(Object.keys @).forEach (key) =>
		x[key] = @[key]
	x

Number.prototype.times = (action) ->
	x = this
	while x > 0
		action()
		x -= 1

Number.prototype.repeat = (x) ->
	out = []
	@times ->
		out.push x
	out

Array.prototype.pushAll = (arr) ->
	@push.apply(@, arr)

Array.prototype.isEmpty = String.prototype.isEmpty = ->
	@length == 0

Number.prototype.times = (act) ->
	count = this
	while count > 0
		act()
		count -= 1

Array.prototype.last = ->
	@[@length - 1]

Array.prototype.allButLast = ->
	@slice 0, @length - 1

Array.prototype.allButAndLast = ->
	[ @allButLast(), @last() ]

Array.prototype.splitBy = (cond) ->
	if @isEmpty()
		[]
	else
		out = []
		cur = []
		@forEach (elem) ->
			if cond elem
				out.push cur
				cur = []
			else
				cur.push elem
		out.push cur

		out

Array.prototype.unCons = ->
	[ @[0], @tail() ]

String.prototype.map =
	Array.prototype.map

String.prototype.contains = (substr) ->
	(@indexOf substr) != -1

Array.prototype.contains = (em) ->
	(@indexOf em) != -1

String.prototype.isAny = ->
	args =
		Array.prototype.slice.call arguments
	Array.prototype.contains.call args, @toString()

Array.prototype.tail = String.prototype.tail = ->
	@slice 1

Array.prototype.interleave = (leaf) ->
	out = @interleavePlus leaf
	out.pop()
	out

Array.prototype.interleavePlus = (leaf) ->
	out = []
	@forEach (em) ->
		out.push em, leaf
	out

Array.prototype.beforeAtAfter = (idx) ->
	[ @slice(0, idx), @[idx], @slice(idx + 1) ]

Array.prototype.indexOfWhere = (cond) ->
	i = 0
	while i < @length
		if cond @[i]
			return i
		i += 1
	return -1

Array.prototype.takeWhile = (cond) ->
	afterLastIndex =
		@indexOfWhere (x) -> not cond(x)
	if afterLastIndex == -1
		[ @, [] ]
	else
		[ (@slice 0, afterLastIndex), (@slice afterLastIndex, @length) ]


Array.prototype.containsWhere = (em) ->
	(@indexOfWhere em) != -1

String.prototype.forEach = Array.prototype.forEach

String.prototype.count = Array.prototype.count = (em) ->
	count = 0
	@forEach (othEm) ->
		if em == othEm
			count += 1
	count

String.prototype.indented = (indent) ->
	@replace /\n/g, "\n#{indent}"

String.prototype.endsWith = (str) ->
	(@slice @length - str.length) == str

String.prototype.withoutEnd = (str) ->
	check @endsWith str
	@slice 0, @length - str.length

String.prototype.startsWith or= (str) ->
	(@slice 0, str.length) == str

String.prototype.withoutStart = (str) ->
	check @startsWith str
	@slice str.length

String.prototype.escapeToJS = ->
	replace =
		"'": "\\'"
		'"': '\\"'
		'\t': '\\t'
		'\n': '\\n'

	reps = Array.prototype.map.call @, (ch) ->
		replace[ch] or ch

	reps.join ''

String.prototype.repeated = (n) ->
	out = ''
	n.times =>
		out += @
	out

String.prototype.indent = (n) ->
	n or= 1

	'\t' + @replace /\n/g, '\n\t'.repeated n

global.check = (cond, err) ->
	unless cond
		if err?
			fail err()
		else
			fail 'Check failed'

global.fail = (err) ->
	if err instanceof Error
		throw err
	else
		throw new Error err

global.todo = ->
	throw new Error 'not implemented'

global.type = (val, type) ->
	unless val?
		throw new Error "Does not exist of type #{type.name}"
	asObject = Object val
	unless asObject instanceof type
		throw new Error \
			"Expected #{asObject} (a #{asObject.constructor.name}) " +
			"to be a #{type.name}"
