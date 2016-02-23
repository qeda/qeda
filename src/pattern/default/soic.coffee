sprintf = require('sprintf-js').sprintf
sop = require './sop'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  housing.pitch = 1.27
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "SOIC%dP%dX%d-%d%s",
    [housing.pitch*100
    housing.leadSpan.nom*100
    height*100
    housing.leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  sop pattern, element
