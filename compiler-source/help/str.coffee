{ check } = require './✔'
{ contains } = require './list'

###
`times` copies of `str` concatenated together.
###
@repeated = (str, times) ->
	([0 ... times].map -> str).join ''

###
Removes any `trimmed`s from the start of `str`.
@param trimmed [String]
  Character to remove.
###
@trimLeftChar = (str, trimmed) ->
	index = 0
	while str[index] == trimmed
		index += 1
	str.slice index

###
Adds `indent` to every line in `str`.
@param indent [String]
###
@indented = (str, indent) ->
	str.replace /\n/g, "\n#{indent}"

###
Whether `start` is at the start of `str`.
###
@startsWith = (str, start) ->
	(str.slice 0, start.length) == start

###
Whether `end` is at the end of `str`.
###
@endsWith = (str, end) ->
	(str.slice str.length - end.length) == end

###
The part of `str` after `start`.
@throw If `str` does not start with `start`.
###
@withoutStart = (str, start) ->
	check (exports.startsWith str, start), ->
		"'#{str}' does not start with '#{start}'"
	str.slice start.length

###
The part of `str` before `end`.
@throw If `str` does not end with `end`.
###
@withoutEnd = (str, end) ->
	check (exports.endsWith str, end), ->
		"'#{str}' does not end with '#{end}'"
	str.slice 0, str.length - end.length
