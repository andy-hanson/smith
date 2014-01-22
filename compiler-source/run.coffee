(require 'source-map-support').install()

#try
(require './smith').main()
#catch error
#	console.log error.stack
#	process.exit 1
