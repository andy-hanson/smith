module.exports = (text) ->
	parts =
		Array.prototype.map.call text, (ch) ->
			if ch.match /[a-zA-Z0-9_]/
				ch
			else
				"$#{ch.charCodeAt 0}$"

	parts.join ''

