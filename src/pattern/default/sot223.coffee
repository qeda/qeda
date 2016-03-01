sprintf = require('sprintf-js').sprintf
assembly = require './common/assembly'
calculator = require './common/calculator'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "SOT%dP%dX%d-%d%s",
    [housing.pitch*100
    housing.leadSpan.nom*100
    height*100
    housing.leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.sot pattern, housing

  pad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width1
    height: padParams.height1
    layer: ['topCopper', 'topMask', 'topPaste']

  # Pads on the left side
  leftCount = housing.leadCount - 1
  pad.x = -padParams.distance / 2
  y = -housing.pitch * (leftCount/2 - 0.5)
  for i in [1..leftCount]
    pad.y = y
    pattern.pad i, pad
    y += housing.pitch

  # Pad on the right side
  pad.x = padParams.distance / 2
  pad.y = 0
  pad.width = padParams.width2
  pad.height = padParams.height2
  pattern.pad leftCount + 1, pad

  # Other layers
  silkscreen.dual pattern, housing
  assembly.polarized pattern, housing
  courtyard.dual pattern, housing, padParams.courtyard
