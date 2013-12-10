fs = require 'fs'
rimraf = require 'rimraf'
###
recurseDirectory = (dir, rel_path, call_back) ->
	##
	Returns names relative to the directory
	##
	(fs.readdirSync "#{dir}/#{rel_path}").forEach (file) ->
		rel = "#{rel_path}/#{file}"
		full = "#{dir}/#{rel}"
		stats = fs.statSync full
		if stats.isFile()
			callBack rel
		else if stats.isDirectory()
			recurseDirectory dir, rel, callBack
###
recurseDirectory = (dir, callBack) ->
	(fs.readdirSync dir).forEach (file) ->
		full = "#{dir}/#{file}"
		stats = fs.statSync full
		if stats.isFile()
			callBack full
		else if stats.isDirectory()
			recurseDirectory full, callBack

allRecursiveFiles = (path) ->
	files = []
	recurseDirectory path, (fileName) ->
		files.push fileName
	files

relativeName = (dir, name) ->
	check name.startsWith dir
	name.withoutStart "#{dir}/" # also remove '/'

copyFlat = (inDir, outDir) ->
	(fs.readdirSync inDir).forEach (file) ->
	copyFile "#{inDir}/#{file}", "#{outDir}/#{file}"

copyFile = (inFile, outFile) ->
	console.log "Copy #{inFile}"
	content = fs.readFileSync inFile, 'utf8'
	fs.writeFileSync outFile, content, 'utf8'

extensionSplit = (name) ->
	(name.split '.').allButAndLast()

ensureDir = (dir) ->
	rimraf.sync dir #destroy it
	unless fs.existsSync dir
		fs.mkdirSync dir

processDirectorySync = (inDir, outDir, filter, callBack) ->
	ensureDir outDir
	try
		processDirectorySyncRecurse inDir, inDir, outDir, filter, callBack
	catch error
		rimraf.sync outDir # destroy output
		throw error

processDirectorySyncRecurse = (origInDir, inDir, outDir, filter, callBack) ->
	(fs.readdirSync inDir).forEach (file) ->
		full = "#{inDir}/#{file}"
		stats = fs.statSync full

		if stats.isFile()
			rel =
				relativeName origInDir, full

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
			newOut = "#{outDir}/#{file}"
			ensureDir newOut
			processDirectorySyncRecurse origInDir, full, outDir, filter, callBack

module.exports =
	#recurseDirectory: recurseDirectory
	#allRecursiveFiles: allRecursiveFiles
	relativeName: relativeName
	#copyFlat: copyFlat
	#copyFile: copyFile
	processDirectorySync: processDirectorySync
	extensionSplit: extensionSplit
