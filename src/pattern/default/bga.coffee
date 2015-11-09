sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'

module.exports = (pattern, housing) ->
  settings = pattern.settings
  leadCount = housing.leadCount ? 2*(housing.rowCount + housing.columnCount)
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "BGA%d%s%dP%dX%d_%dX%dX%d",
    leadCount,
    if settings.ball.collapsible then 'C' else 'N'
    [housing.pitch*100
    housing.columnCount
    housing.rowCount
    housing.bodyLength.nom*100
    housing.bodyWidth.nom*100
    height*100]
    .map((a) => Math.round a)...

  settings = pattern.settings
