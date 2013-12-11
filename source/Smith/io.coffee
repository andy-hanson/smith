fs = require 'fs'

join = (parent, sub) ->
	if parent == ''
		sub
	else
		"#{parent}/#{sub}"

#allRecursiveFiles = (path) ->
#	files = []
#	recurseDirectory path, (fileName) ->
#		files.push fileName
#	files

relativeName = (dir, name) ->
	check name.startsWith dir
	name.withoutStart "#{dir}/" # also remove '/'

#copyFlat = (inDir, outDir) ->
#	(fs.readdirSync inDir).forEach (file) ->
#	copyFile "#{inDir}/#{file}", "#{outDir}/#{file}"

#copyFile = (inFile, outFile) ->
#	content = fs.readFileSync inFile, 'utf8'
#	fs.writeFileSync outFile, content, 'utf8'

statKindSync = (name) ->
	stat =
		fs.statSync name
	if stat.isFile()
		'file'
	else if stat.isDirectory()
		'directory'
	else
		'other'

extensionSplit = (name) ->
	(name.split '.').allButAndLast()

ensureDir = (dir) ->
	unless fs.existsSync dir
		fs.mkdirSync dir

dirOf = (fullName) ->
	(fullName.split '/').allButLast().join '/'

plainName = (fullName) ->
	(fullName.split '/').last()

readTextSync = (fileName) ->
	fs.readFileSync fileName, 'utf8'




recurseDirectorySync = (dir, callBack) ->
	(fs.readdirSync dir).forEach (file) ->
		full = "#{dir}/#{file}"
		switch statKindSync full
			when 'file'
				callBack full
			when 'directory'
				recurseDirectorySync full, callBack
			else
				null


###
Callback takes dir and text.
###
readFilesNamedSync = (inDir, name, callBack) ->
	type inDir, String
	type name, String
	type callBack, Function

	filter = (fileName) ->
		(plainName fileName) == name

	recurseDirectoryFilesSync inDir, filter, (fileName, text) ->
		callBack (dirOf fileName), text



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

###
TODO: use recurseDirectorySync!
###

processDirectorySync = (inDir, outDir, filter, callBack) ->
	ensureDir outDir
	processDirectorySyncRecurse inDir, inDir, outDir, filter, callBack

###
callBack takes dir (relative to inDir) and text.
###
processDirectorySyncRecurse = (origInDir, inDir, outDir, filter, callBack) ->
	(fs.readdirSync inDir).forEach (file) ->
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

				toWrites.forEach (toWrite) ->
					[ shortName, content ] = toWrite
					type shortName, String
					type content, String
					outFile = "#{outDir}/#{shortName}"
					fs.writeFileSync outFile, content, 'utf8'

		else if stats.isDirectory()
			ensureDir "#{outDir}/#{rel}"
			processDirectorySyncRecurse origInDir, full, outDir, filter, callBack

module.exports =
	relativeName: relativeName
	dirOf: dirOf
	recurseDirectorySync: recurseDirectorySync
	processDirectorySync: processDirectorySync
	extensionSplit: extensionSplit
	readFilesNamedSync: readFilesNamedSync
	statKindSync: statKindSync
	join: join
