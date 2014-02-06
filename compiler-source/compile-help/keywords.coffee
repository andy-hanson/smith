###
Introduce a new Meta quote block.
Easy to add new ones.
###
@metaText =
	[ 'doc', 'how', 'err', 'oth' ]

###
Introduce a new Meta function.
All are unique and have different arguments.
###
@metaFun =
	[ 'in', 'out', 'eg' ]

###
Keywords that are in a function's meta.
Does not include 'in' and 'out' because those are not in the meta.
###
@allMeta =
	[ 'eg' ].concat @metaText

###
Followed by a module name.
###
@useLike =
	[ 'use', 'use!', 'super', 'trait' ]

###
Introduce a DefLocal.
###
@local =
	[ 'val', 'lazy' ]

###
Have special meanings (not Names).
###
@specialVar =
	[ 'me', 'it' ]

@special =
	(exports.local.concat exports.specialVar).concat [ '\n' ]
