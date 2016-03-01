sprintf = require('sprintf-js').sprintf
chip = require './chip'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "SODFL%02d%02dX%d%s",
    [housing.leadSpan.nom*10
    housing.bodyWidth.nom*10
    height*100]
    .map((v) => Math.round v)...,
    settings.densityLevel

  housing.sodfl = true
  chip pattern, element
