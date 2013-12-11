(require 'source-map-support').install()

requirejs =
	require 'requirejs'

requirejs.config
	nodeRequire: require

	#baseUrl: 'js-std'

	#paths:
	#	Prelude: 'Prelude/index'
	#	Bag: 'Bag/index'

#require './Main'

requirejs ['./Main'], (Main) ->
	null
