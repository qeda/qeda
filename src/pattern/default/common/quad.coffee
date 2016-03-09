sprintf = require('sprintf-js').sprintf

assembly = require './assembly'
calculator = require './calculator'
copper = require './copper'
courtyard = require './courtyard'
silkscreen = require './silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  leadCount = housing.leadCount ? 2*(housing.rowCount + housing.columnCount)
  hasTab = housing.tabWidth? and housing.tabLength?
  if hasTab then ++leadCount

  if housing.cqfp
    abbr = 'CQFP'
    option = 'qfp'
    length = housing.rowSpan.nom
    width = housing.columnSpan.nom
  else if housing.qfn
    abbr = (if housing.pullBack? then 'P' else '') + 'QFN'
    option = 'qfn'
    length = housing.bodyLength.nom
    width = housing.bodyWidth.nom
  else
    abbr = 'QFP'
    option = 'qfp'
    length = housing.columnSpan.nom
    width = housing.rowSpan.nom

  pattern.name ?= sprintf "%s%dP%dX%dX%d-%d%s",
    abbr,
    [housing.pitch*100
    length*100
    width*100
    housing.height.max*100
    leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.quad pattern, housing, option
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
  silkscreen.quad pattern, housing
  assembly.polarized pattern, housing
  courtyard.quad pattern, housing, padParams.courtyard

  copper.tab pattern, housing
