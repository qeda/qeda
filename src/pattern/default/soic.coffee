sprintf = require('sprintf-js').sprintf
sop = require './sop'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.pitch = 1.27
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "SOIC%dP%dX%d-%d",
    [housing.pitch*100
    housing.leadSpan.nom*100
    height*100
    housing.leadCount]
    .map((v) => Math.round v)...

  sop pattern, element
