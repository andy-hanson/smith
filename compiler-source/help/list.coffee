{ check } = require './✔'

module.exports =
	rightUnCons: (list) ->
		[ (list.slice 0, list.length - 1), module.exports.last list ]

	unCons: (list) ->
		[ list[0], module.exports.tail list ]

	indexOfWhere: (list, condition) ->
		index = 0
		while index < list.length
			if condition list[index]
				return index
			index += 1
		return -1

	splitOnceWhere: (list, condition) ->
		afterLastIndex =
			module.exports.indexOfWhere list, (value) -> not condition value
		if afterLastIndex == -1
			[ list, [] ]
		else
			[ (list.slice 0, afterLastIndex), (list.slice afterLastIndex, list.length) ]

	isEmpty: (list) ->
		list.length == 0

	last: (list) ->
		list[list.length - 1]

	split: (list, condition) ->
		if module.exports.isEmpty list
			[]
		else
			out = []
			cur = []
			list.forEach (elem) ->
				if condition elem
					out.push cur
					cur = []
				else
					cur.push elem
			out.push cur

			out

	interleave: (list, interleaved) ->
		out = module.exports.interleavePlus list, interleaved
		out.pop()
		out

	interleavePlus: (list, interleaved) ->
		out = []
		for em in list
			out.push em, interleaved
		out

	repeat: (times, value) ->
		[1..times].map ->
			value

	pushAll: (list, elements) ->
		Array.prototype.push.apply list, elements

	tail: (list) ->
		Array.prototype.slice.call list, 1

	containsWhere: (list, condition) ->
		for value in list
			return true if condition value
		return false

	countWhere: (list, condition) ->
		count = 0
		list.forEach (value) ->
			if condition value
				count += 1
		count