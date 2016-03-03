sprintf = require('sprintf-js').sprintf

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  leadCount = housing.leadCount ? housing.rowCount*housing.columnCount

  pattern.name ?= sprintf "CON%02dP%dX%dX%d-%d%s",
    [housing.pitch*100
    housing.bodyLength.nom*10
    housing.bodyWidth.nom*10
    housing.height.max*10
    leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel
