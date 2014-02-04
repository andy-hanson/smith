{ check } = require './✔'

module.exports =
	times: (n, action) ->
		check n >= 0
		if n > 0
			[0..n-1].forEach action