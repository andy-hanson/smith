{ check } = require './✔'
{ contains } = require './list'

module.exports =
	repeated: (str, times) ->
		if times == 0
			''
		else
			x = ([0..times-1].map -> str).join ''
			check (x.length == str.length * times)
			x

	trimLeftChar: (str, trimmed) ->
		index = 0
		while str[index] == trimmed
			index += 1
		str.slice index

	indented: (str, indent) ->
		str.replace /\n/g, "\n#{indent}"

	escapeToJS: (str) ->
		###
		replace =
			"'": "\\'"
			'"': '\\"'
			'\t': '\\t'
			'\n': '\\n'

		Array.prototype.map.call str, (ch) ->
			replace[ch] or ch
		.join ''
		###
		str.replace /'|"|\t|\n/g, (x) ->
			switch x
				when '\n'
					'\\n'
				when '\t'
					'\\t'
				when "'", '"'
					"\\#{x}"

	startsWith: (str, start) ->
		(str.slice 0, start.length) == start

	endsWith: (str, end) ->

		(str.slice str.length - end.length) == end

	withoutStart: (str, start) ->
		check (module.exports.startsWith str, start), ->
			"'#{str}' does not start with '#{start}'"
		str.slice start.length

	withoutEnd: (str, end) ->
		check (module.exports.endsWith str, end), ->
			"'#{str}' does not end with '#{end}'"
		str.slice 0, str.length - end.length
