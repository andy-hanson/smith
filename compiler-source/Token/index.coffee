keywords = require '../compile-help/keywords'

@Def = require './Def'
@Token = require './Token'
@Name = require './Name'
@Group = require './Group'
{ @Literal, @NumberLiteral, @JavascriptLiteral, @StringLiteral }=
	require './Literal'
@MetaText = require './MetaText'
@Special = require './Special'
@Use = require './Use'

# Whether `token` is a newline.
@nl = (token) ->
	token instanceof exports.Special and token.kind == '\n'
# Whether `token` is a bar (starts a function).
@bar = (token) ->
	token instanceof exports.Special and token.kind == '|'
# Whether `token` is called on the last one.
@dotLikeName = (token) ->
	token instanceof exports.Name and token.kind in [ '.x', '@x', '.x_' ]
# Whether `token` is a name of type 'x'.
@plainName = (token) ->
	token instanceof exports.Name and token.kind == 'x'
# Whether `token` is a type (':x').
@typeName = (token) ->
	token instanceof exports.Name and token.kind == ':x'
# Whether `token` is an ellipsis ('...x')
@ellipsisName = (token) ->
	token instanceof exports.Name and token.kind == '...x'
# Whether `token` is an indented block.
@indented = (token) ->
	token instanceof exports.Group and token.kind == '→'
# Whether `token` is an `in`, `out`, or `eg`.
@metaGroup = (token) ->
	token instanceof exports.Group and token.kind in keywords.metaFun
# Whether `token` is indented JavaScript.
@indentedJS = (token) ->
	token instanceof exports.JavascriptLiteral and token.kind == 'indented'
# Whether `token` is a local definer (∙∘)
@defLocal = (token) ->
	token instanceof exports.Special and token.kind in [ '∙', '∘' ]
# Whether `token` is a super use.
@super = (token) ->
	token instanceof exports.Use and token.kind == 'super'
# Whether `token` is '`it`'.
@it = (token) ->
	token instanceof exports.Special and token.kind == 'it'
