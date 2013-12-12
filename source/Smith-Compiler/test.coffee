(require 'source-map-support').install()

try
	(require './smith').test()
catch error
	console.log error.stack
	process.exit 1

