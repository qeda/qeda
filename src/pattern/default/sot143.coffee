sprintf = require('sprintf-js').sprintf
assembly = require './common/assembly'
calculator = require './common/calculator'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  pattern.name ?= sprintf "SOT%dP%dX%d-%d%s%s",
    [housing.pitch*100
    housing.leadSpan.nom*100
    housing.height.max*100
    housing.leadCount]
    .map((v) => Math.round v)...,
    if housing.reverse then 'R' else '',
    settings.densityLevel

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.sot pattern, housing

  pad1 =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width1
    height: padParams.height1
    layer: ['topCopper', 'topMask', 'topPaste']
  pad2 =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width2
    height: padParams.height2
    layer: ['topCopper', 'topMask', 'topPaste']

  if housing.reversed
    pad1.x = -padParams.distance / 2
    pad1.y = -housing.pitch/2
    pattern.pad 1, pad1

    pad2.x = -padParams.distance / 2
    pad2.y = housing.pitch/2 + padParams.height1/2 - padParams.height2/2
    pattern.pad 2, pad2
  else
    pad2.x = -padParams.distance / 2
    pad2.y = -housing.pitch/2 - padParams.height1/2 + padParams.height2/2
    pattern.pad 1, pad2

    pad1.x = -padParams.distance / 2
    pad1.y = housing.pitch/2
    pattern.pad 2, pad1

  pad1.x = padParams.distance / 2
  pad1.y = housing.pitch/2
  pattern.pad 3, pad1
  pad1.y = -housing.pitch/2
  pattern.pad 4, pad1

  silkscreen.dual pattern, housing
  assembly.polarized pattern, housing
  courtyard.dual pattern, housing, padParams.courtyard
