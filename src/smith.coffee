require './helpers'
#[ './helpers', './parse', './lex', './compile', 'fs', 'optimist']
io = require './io'
fs = require 'fs'
optimist = require 'optimist'
compile = require './compile'
coffee = require 'coffee-script'

#console.log [1, 2, 3].interleave 4

compileAndWrite = (inFile, outFile) ->
	###
	Compile a single file to a single output.
	###
	console.log "Compiling #{inFile} to #{outFile}"

	source =
		fs.readFileSync inFile, 'utf8'
	compiled =
		compile source, inFile, outFile

	fs.writeFileSync \
		outFile,
		compiled.code
	fs.writeFileSync \
		"#{outFile}.map",
		compiled.map

compileDir = (inDir, outDir) ->
	#Also copy 'prelude' there.
	#io.copyFlat 'prelude', outDir

	io.processDirectory inDir, outDir, (file, read) ->
		[ name, ext ] = io.extensionSplit file
		switch ext
			when 'smith'
				source = read()
				out = "#{name}.js"
				compiled = compile source, file, out

				[ [ out, compiled.code ], [ "#{out}.map", compiled.map.toString() ] ]

			when 'js'
				# Just copy it
				[ [ file, read() ] ]

			when 'coffee'
				[ [ "#{name}.js", coffee.compile read() ] ]

			else
				console.log "Ignoring file #{file}"
				[ ]

	###
	io.recurseDirectory inDir, (file) ->
		if file.endsWith '.smith'
			rel = (io.relativeName inDir, file).withoutEnd '.smith'
			outFile = "#{outDir}/#{rel}.js"
			compileAndWrite file, outFile
		else if file.endsWith '.js'
			io.copyFile file, "#{outDir}#{file.withoutStart inDir}"
	###

main = ->
	argv =
		optimist.options
			i:
				alias: 'in'
				describe: 'ay ay ay!'
				default: '.'
			o:
				alias: 'out'
				default: './smith-js'
		.argv

	unless argv.help
		unless argv._.isEmpty()
			throw new Error "Unexpected #{argv._}"

		#_in = 'smith'
		#out = 'smith/out'

		compileDir argv.in, argv.out

test = ->
	(require './lexSpec')()

	#console.log argv
	#console.log commandline.in
	#(require './compile').test()

module.exports =
	parse:		require './parse'
	lex:		require './lex'
	compile:	compile
	compileAndWrite: compileAndWrite
	compileDir: compileDir
	main: main
	test: test


