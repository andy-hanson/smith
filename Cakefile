require('just-the-job') ->
	@execTask 'update', 'DESCRIBE', [],
		'npm update'
	@execTask 'clean', 'DESCRIBE', [], \
		'rm -rf js js-std'
	@execTask 'lint', 'DESCRIBE', [], \
		'coffeelint -f source/lintConfig.json source/*.coffee source/*/*.coffee'
	@execTask 'compile-compiler', 'DESCRIBE', [], \
		'coffee --compile --bare --map --output compiler-js source/Smith-Compiler'
	@execTask 'compile-smith', 'DESCRIBE', ['compile-compiler'], \
		'bin/smith --quiet'
	@execTask 'run-smith', 'DESCRIBE', ['compile-smith'], \
		'node js/run.js'
	@execTask 'watch', 'DESCRIBE', [], \
		'bin/smith --in source --out js-smith --watch'
	@execTask 'publish', 'DESCRIBE', [], \
		'echo TODO'
