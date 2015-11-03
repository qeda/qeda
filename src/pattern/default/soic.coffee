sprintf = require('sprintf-js').sprintf
sop = require './sop'

module.exports = (pattern) ->
  housing = pattern.housing
  housing.pitch = 1.27
  pattern.name ?= sprintf "SOIC%dP%dX%d-%d",
    [housing.pitch*100
    housing.leadSpan.nom*100
    housing.height.max*100
    housing.leadCount]
    .map((a) => Math.round a)...
  sop pattern
