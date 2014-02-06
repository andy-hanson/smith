fs = require 'fs'
path = require 'path'

###
Whether `name` names a 'file', a 'directory', or 'other'.
###
statKindSync = (name) ->
	stat =
		fs.statSync name
	if stat.isFile()
		'file'
	else if stat.isDirectory()
		'directory'
	else
		'other'

# @noDoc
recurseDirectorySync = (dir, callBack) ->
	(fs.readdirSync dir).forEach (file) ->
		full = path.join dir, file
		switch statKindSync full
			when 'file'
				callBack full
			when 'directory'
				recurseDirectorySync full, callBack
			else
				null

module.exports = (dir) ->
	recurseDirectorySync dir, (file) ->
		if (file.slice file.length - 3) == '.js'
			x = require file
			console.log "Required #{x}"
