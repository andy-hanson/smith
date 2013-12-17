require('just-the-job') ->
	@task 'generate-sublime-files',
		'Generate sublime text .tmLanguage and .tmTheme', '''
		python -c """
		import yaml, json, plistlib
		for x in [ 'Theme', 'Language' ]:
			outName = 'editor/Smith.tm' + x
			inName = outName + '.yaml'
			content = yaml.load(open(inName))
			plistlib.writePlist(content, outName)
		"""'''
	@task 'install-sublime-files',
		'Put sublime files in sublime user packages'
		['generate-sublime-files']
		'cp editor/Smith.tmLanguage editor/Smith.tmTheme ~/.config/sublime-text-3/Packages/User'
	@task 'update',
		'Get latest versions of modules',
		'npm update'
	@task 'clean',
		'Get rid of things generated by building',
		'rm -rf editor/Smith.tmTheme editor/Smith.tmLanguage node_modules compiler-js js'
	@job 'lint-coffee',
		'coffeelint --file source/coffeelint-config.json source'
	@job 'lint-JS',
		'jshint source'
	@task 'lint',
		'Check code formatting of coffeescript and javascript',
		['lint-coffee', 'lint-JS']
	@task 'compile-compiler',
		'Compile the Smith-Compiler to compiler-js',
		'coffee --compile --bare --map --output compiler-js source/Smith-Compiler'
	@task 'compile',
		'Compile all code in source',
		['compile-compiler'],
		'bin/smith --quiet'  # --print-module-defines # --just Main.smith
	@task 'just-run-smith', 'node js/Standard/run.js'
	@task 'run',
		'Run the compiled program',
		['compile', 'just-run-smith']
	@task 'watch',
		'Compile all modifications to source',
		'bin/smith --in source --out js-smith --watch'

	@task 'all',
		'Do everything!',
		['clean', 'generate-sublime-files', 'update', 'lint', 'run']
