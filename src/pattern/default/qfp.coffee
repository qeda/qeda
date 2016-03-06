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
  hasTab = housing.tabWidth? and housing.tabLength?
  if hasTab then ++leadCount
  pattern.name ?= sprintf "%sQFP%dP%dX%dX%d-%d%s",
    if housing.cqfp then 'C' else '',
    [housing.pitch*100
    housing.rowSpan.nom*100
    housing.columnSpan.nom*100
    housing.height.max*100
    leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.qfp pattern, housing
  padParams.pitch = housing.pitch
  padParams.rowCount = housing.rowCount
  padParams.columnCount = housing.columnCount
  padParams.rowPad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width1
    height: padParams.height1
    distance: padParams.distance1
    layer: ['topCopper', 'topMask', 'topPaste']
  # Rotated to 90 degree (swap width and height)
  padParams.columnPad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.height2
    height: padParams.width2
    distance: padParams.distance2
    layer: ['topCopper', 'topMask', 'topPaste']

  copper.quad pattern, padParams
  silkscreen.qfp pattern, housing
  assembly.polarized pattern, housing
  courtyard.quad pattern, housing, padParams.courtyard

  copper.tab pattern, housing
