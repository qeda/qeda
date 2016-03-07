sprintf = require('sprintf-js').sprintf
assembly = require './common/assembly'
calculator = require './common/calculator'
copper = require './common/copper'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  leadCount = housing.leadCount
  hasTab = housing.tabWidth? and housing.tabLength?
  if hasTab then ++leadCount

  pattern.name ?= sprintf "%sSON%dP%dX%dX%d-%d%s",
    if housing.pullBack? then 'P' else '',
    [housing.pitch*100
    housing.bodyLength.nom*100
    housing.bodyWidth.nom*100
    housing.height.max*100
    leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.son pattern, housing

  padParams.pitch = housing.pitch
  padParams.count = housing.leadCount
  padParams.order = 'round'
  padParams.pad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width
    height: padParams.height
    layer: ['topCopper', 'topMask', 'topPaste']

  copper.dual pattern, padParams
  if padParams.width2?
    firstPad = pattern.pads[Object.keys(pattern.pads)[0]]
    width2 = padParams.width2
    dx = width2 - firstPad.width
    firstPad.x += dx
    firstPad.width = width2

  silkscreen.son pattern, housing
  assembly.polarized pattern, housing
  courtyard.dual pattern, housing, padParams.courtyard

  copper.tab pattern, housing
