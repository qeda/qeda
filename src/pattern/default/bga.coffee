sprintf = require('sprintf-js').sprintf
assembly = require './common/assembly'
calculator = require './common/calculator'
copper = require './common/copper'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  leadCount = housing.leadCount ? 2*(housing.rowCount + housing.columnCount)
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "BGA%d%s%dP%dX%d_%dX%dX%d%s",
    leadCount,
    if settings.ball.collapsible then 'C' else 'N'
    [housing.pitch*100
    housing.columnCount
    housing.rowCount
    housing.bodyLength.nom*100
    housing.bodyWidth.nom*100
    height*100]
    .map((v) => Math.round v)...,
    settings.densityLevel

  housing.rowPitch ?= housing.pitch
  housing.columnPitch ?= housing.pitch

  padParams = calculator.bga pattern, housing
  pad =
    type: 'smd'
    width: padParams.width
    height: padParams.height
    shape: 'circle'
    layer: ['topCopper', 'topMask', 'topPaste']

  copper.gridArray pattern, element, pad
  silkscreen.gridArray pattern, housing
  assembly.polarized pattern, housing
  courtyard.gridArray pattern, housing, padParams.courtyard
