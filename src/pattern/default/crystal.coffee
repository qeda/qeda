sprintf = require('sprintf-js').sprintf
chip = require './chip'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  height = housing.height.max ? housing.height
  housing.crystal = true
  abbr = 'XTAL'
  pattern.name ?= sprintf "%s%02dX%02dX%d%s",
    abbr,
    [housing.bodyLength.nom*10
    housing.bodyWidth.nom*10
    height*100]
    .map((v) => Math.round v)...,
    settings.densityLevel

  chip pattern, element
