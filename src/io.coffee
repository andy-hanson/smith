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
	name.slice dir.length + 1 # also remove '/'

copyFlat = (inDir, outDir) ->
	(fs.readdirSync inDir).forEach (file) ->
	copyFile "#{inDir}/#{file}", "#{outDir}/#{file}"

copyFile = (inFile, outFile) ->
	console.log "Copy #{inFile}"
	content = fs.readFileSync inFile, 'utf8'
	fs.writeFileSync outFile, content, 'utf8'

extensionSplit = (name) ->
	name.split '.'

ensureDir = (dir) ->
	rimraf.sync dir #destroy it
	unless fs.existsSync dir
		fs.mkdirSync dir

processDirectory = (inDir, outDir, callBack) ->
	ensureDir outDir
	try
		processDirectoryRecurse inDir, outDir, callBack
	catch error
		rimraf.sync outDir # destroy output
		throw error

processDirectoryRecurse = (inDir, outDir, callBack) ->
	(fs.readdirSync inDir).forEach (file) ->
		full = "#{inDir}/#{file}"
		stats = fs.statSync full

		if stats.isFile()
			toWrites =
				callBack file, ->
					fs.readFileSync full, 'utf8'
			type toWrites, Array
			toWrites.forEach (toWrite) ->
				[ shortName, content ] = toWrite
				type shortName, String
				type content, String
				outFile = "#{outDir}/#{shortName}"
				#console.log "Writing to #{outFile}"
				fs.writeFileSync outFile, content, 'utf8'

		else if stats.isDirectory()
			newOut = "#{outDir}/#{file}"
			ensureDir newOut
			processDirectoryRecurse full, "#{outDir}/#{file}", callBack

module.exports =
	#recurseDirectory: recurseDirectory
	#allRecursiveFiles: allRecursiveFiles
	relativeName: relativeName
	#copyFlat: copyFlat
	#copyFile: copyFile
	processDirectory: processDirectory
	extensionSplit: extensionSplit
