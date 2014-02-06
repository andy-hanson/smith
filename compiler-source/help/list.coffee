{ check } = require './✔'

###
Whether `condition` is true for any element of `list`.
###
@containsWhere = (list, condition) ->
	for value in list
		if condition value
			return true
	false

###
How many elements in list satisfy `condition`.
###
@countWhere = (list, condition) ->
	count = 0
	list.forEach (value) ->
		if condition value
			count += 1
	count

###
Index where condition is true, or -1.
###
@indexOfWhere = (list, condition) ->
	index = 0
	while index < list.length
		if condition list[index]
			return index
		index += 1
	return -1

###
A new list with `interleaved` in between every element of `list`.
###
@interleave = (list, interleaved) ->
	out = exports.interleavePlus list, interleaved
	out.pop()
	out

###
Like `interleave` but with another of `interleaved` at the end.
###
@interleavePlus = (list, interleaved) ->
	out = [ ]
	list.forEach (element) ->
		out.push element, interleaved
	out

###
Whether `list` contains no elements.
###
@isEmpty = (list) ->
	list.length == 0

###
The last element in `list`.
###
@last = (list) ->
	list[list.length - 1]

###
A list of `times` `value`s.
###
@repeat = (times, value) ->
	[1..times].map ->
		value

###
Everything but the last element, and the last element.
@return [(Array, Object)]
###
@rightUnCons = (list) ->
	[ (list.slice 0, list.length - 1), module.exports.last list ]

###
Breaks `list` by elements where `condition`.
@return [Array<Array>]
  Arrays where `condition` is false.
  Elements where `condition` is true are discarded.
###
@splitWhere = (list, condition) ->
	if module.exports.isEmpty list
		[ ]
	else
		out = [ ]
		cur = [ ]
		list.forEach (elem) ->
			if condition elem
				out.push cur
				cur = [ ]
			else
				cur.push elem
		out.push cur
		out

###
Every element but the first.
###
@tail = (list) ->
	Array.prototype.slice.call list, 1

###
Everything up to the first element not satisfying `condition`, and the rest.
(The concatenation of the results is `list`).
If nothing satisfies `condition`, ( list, [ ] ).
@return [(Array, Array)]
###
#@takeAndAfter = (list, condition) ->
#	afterLastIndex =
#		module.exports.indexOfWhere list, (value) -> not condition value
#	if afterLastIndex == -1
#		[ list, [ ] ]
#	else
#		[ (list.slice 0, afterLastIndex), (list.slice afterLastIndex, list.length) ]

###
The first element, and everything else.
@return [(Array, Object)]
###
@unCons = (list) ->
	[ list[0], module.exports.tail list ]
