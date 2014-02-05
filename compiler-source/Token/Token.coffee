###
Represents a single parsed element.
All should have @pos.
###
module.exports = class Token
	###
	Tokens may implement this so errors shows extra information.
	@abstract
	###
	show: ->
		''

	# Shows up in source code errors. See `show`.
	toString: ->
		"#{@constructor.name}(#{@show()})@#{@pos}"