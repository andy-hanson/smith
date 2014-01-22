fs = require 'fs'
path = require 'path'

relativeName = (dir, name) ->
	name.withoutStart "#{dir}/" # also remove '/'

statKindSync = (name) ->
	stat =
		fs.statSync name
	if stat.isFile()
		'file'
	else if stat.isDirectory()
		'directory'
	else
		'other'

ensureDir = (dir) ->
	unless fs.existsSync dir
		fs.mkdirSync dir

readTextSync = (fileName) ->
	fs.readFileSync fileName, 'utf8'

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


extensionSplit = (name) ->
	ext =
		path.extname name
	if ext == ''
		[ name, '' ]
	else
		extNoDot =
			ext.withoutStart '.'
		[ (name.withoutEnd ext), extNoDot ]

###
Callback takes dir and text.
###
readFilesNamedSync = (inDir, name, callBack) ->
	type inDir, String
	type name, String
	type callBack, Function

	filter = (fileName) ->
		(path.basename fileName) == name

	recurseDirectoryFilesSync inDir, filter, (fileName, text) ->
		callBack (path.dirname fileName), text



###
callBack takes dir (relative to inDir) and text.
###
recurseDirectoryFilesSync = (inDir, filter, callBack) ->
	type inDir, String
	type filter, Function
	type callBack, Function

	recurseDirectorySync inDir, (fileName) ->
		rel =
			relativeName inDir, fileName
		if filter rel
			text =
				readTextSync fileName
			callBack rel, text



processDirectorySync = (inDir, outDir, filter, callBack) ->
	ensureDir outDir
	processDirectorySyncRecurse inDir, inDir, outDir, filter, callBack

###
callBack takes dir (relative to inDir) and text.
###
processDirectorySyncRecurse = (origInDir, inDir, outDir, filter, callBack) ->
	x = fs.readdirSync inDir

	x.forEach (file) ->
		full = "#{inDir}/#{file}"
		stats = fs.statSync full
		rel =
			relativeName origInDir, full

		if stats.isFile()
			if filter rel
				text =
					fs.readFileSync full, 'utf8'
				toWrites =
					callBack rel, text

				type toWrites, Array

				toWrites.forEach (toWrite) ->
					[ shortName, content ] = toWrite
					type shortName, String
					type content, String
					outFile = path.join outDir, shortName
					fs.writeFileSync outFile, content, 'utf8'

		else if stats.isDirectory()
			ensureDir path.join outDir, rel
			processDirectorySyncRecurse origInDir, full, outDir, filter, callBack

module.exports =
	extensionSplit: extensionSplit
	relativeName: relativeName
	recurseDirectorySync: recurseDirectorySync
	processDirectorySync: processDirectorySync
	readFilesNamedSync: readFilesNamedSync
	statKindSync: statKindSync
	recurseDirectoryFilesSync: recurseDirectoryFilesSync
