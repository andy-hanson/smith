{ check } = require './✔'

###
Performs `action` `n` times.
###
@times = (n, action) ->
	check n >= 0
	[0 ... n].forEach action
