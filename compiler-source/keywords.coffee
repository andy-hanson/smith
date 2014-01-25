local = [ '∙', '∘' ]
specialVar = [ 'me', 'it' ]

module.exports =
	metaText:
		[ 'doc', 'how', 'err', 'oth' ]
	metaFun:
		[ 'in', 'out', 'eg' ]
	useLike:
		[ 'use', 'use!', 'super', 'trait' ]
	local:
		local
	specialVar:
		specialVar
	special:
		local.concat specialVar
	useAll:
		'all-modules'