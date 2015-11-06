sprintf = require('sprintf-js').sprintf

module.exports = (pattern, housing) ->
  pattern.name ?= sprintf "QFN%dP%dX%dX%d-%d",
    [housing.pitch*100
    housing.bodyWidth.nom*100
    housing.bodyLength.nom*100
    housing.height*100
    housing.leadCount]
    .map((a) => Math.round a)...
