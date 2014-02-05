fs = require 'fs'
path = require 'path'
{ check, type } = require './✔'
{ withoutStart, withoutEnd } = require './str'

###
Ensures that `directoryPath` is the name of a directory.
If it doesn't exist, makes it.
If it does, and is a file, throws an error.
###
ensureDir = (directoryPath) ->
	if fs.existsSync directoryPath
		check (statKindSync directoryPath) == 'directory', ->
			"#{directoryPath} is not a directory"
	else
		fs.mkdirSync directoryPath

###
Returns the file name without the extension, and the extension.
###
extensionSplit = (name) ->
	ext =
		path.extname name
	if ext == ''
		[ name, '' ]
	else
		extNoDot =
			withoutStart ext, '.'
		[ (withoutEnd name, ext), extNoDot ]

###
Recursively processes the files in `inDir` and writes to `outDir`.
@param inDir [String]
  Directory to read files from.
@param outDir [String]
  Directory to write to (created as needed).
@param filter [(String) -> Bool]
  Whether a file of the given name should be processed.
@param callBack [(String, String) -> Array<(String, String>]
  Takes in a name relative to `inDir` and file content, and
  outputs a list of [ name, content ] pairs to write to `outDir`.
###
processDirectorySync = (inDir, outDir, filter, callBack) ->
	type inDir, String, outDir, String, filter, Function, callBack, Function

	recurse = (fullName) ->
		relName =
			relativeName inDir, fullName

		switch statKindSync fullName
			when 'file'
				if filter relName
					text =
						readTextSync fullName
					toWrites =
						callBack relName, text
					type toWrites, Array
					toWrites.forEach (toWrite) ->
						[ shortName, content ] = toWrite
						type shortName, String, content, String
						outFile =
							path.join outDir, shortName
						writeTextSync outFile, content

			when 'directory'
				ensureDir path.join outDir, relName
				(fs.readdirSync fullName).forEach (shortName) ->
					recurse path.join fullName, shortName

			else
				# ignore it

	recurse inDir


###
The path of `name` from `dir`. Eg `(relativeName 'a/b', 'a/b/c/d') == 'c/d'`
@param name [String] name of a file in `dir`.
@param dir [String] Directory of `name`.
No relation to path.relative
###
relativeName = (dir, name) ->
	if dir == name
		''
	else
		withoutStart name, "#{dir}/"

###
Runs `callBack` on every file in `inDir` (and its subdirectories) called `name`.
@param callBack [(String, String) -> ()]
	Does something with a file name and its content.
###
readFilesNamedSync = (inDir, name, callBack) ->
	type inDir, String, name, String, callBack, Function

	filter = (fileName) ->
		(path.basename fileName) == name

	recurseDirectoryFilesSync inDir, filter, (fileName, text) ->
		callBack (path.dirname fileName), text

# @noDoc
readTextSync = (fileName) ->
	fs.readFileSync fileName, 'utf8'


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

###
In `inDir`, calls `callBack` on each file name and content that passes `filter`.
@param inDir [String]
  Name of directory to recurse through.
@param filter [Function]
  Whether a file should be read.
@param callBack [(String, String) -> ()]
  Called on each file name (relative to `inDir`) and its content.
###
recurseDirectoryFilesSync = (inDir, filter, callBack) ->
	type inDir, String, filter, Function, callBack, Function

	recurseDirectorySync inDir, (fileName) ->
		rel =
			relativeName inDir, fileName
		if filter rel
			text =
				readTextSync fileName
			callBack rel, text

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
writeTextSync = (fileName, content) ->
	fs.writeFileSync fileName, content, 'utf8'


# @noDoc
module.exports =
	extensionSplit: extensionSplit
	processDirectorySync: processDirectorySync
	relativeName: relativeName
	readFilesNamedSync: readFilesNamedSync
	recurseDirectoryFilesSync: recurseDirectoryFilesSync
	statKindSync: statKindSync
