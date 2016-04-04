sprintf = require('sprintf-js').sprintf

assembly = require './common/assembly'
calculator = require './common/calculator'
copper = require './common/copper'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  pattern.name ?= sprintf "TO%dP%dX%dX%d-%d%s",
    [housing.pitch*100
    housing.bodyLength.nom*100
    housing.bodyWidth.nom*100
    housing.height.max*100
    housing.leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.pak pattern, housing
  pad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width1
    height: padParams.height1
    layer: ['topCopper', 'topMask', 'topPaste']
  pitch = housing.pitch
  leadCount = housing.leadCount

  pins = element.pins
  # Pads on the left side
  pad.x = -padParams.distance1/2
  y = -pitch * (leadCount/2 - 0.5)
  for i in [1..leadCount]
    pad.y = y
    if pins[i]? then pattern.pad i, pad # Add only if exists
    y += pitch

  # Tab pad
  pad.width = padParams.width2
  pad.height = padParams.height2
  pad.x = padParams.distance2/2
  pad.y = 0
  pattern.pad leadCount + 1, pad

  copper.mask pattern
  silkscreen.pak pattern, housing
  assembly.pak pattern, element
  courtyard.pak pattern, housing, padParams.courtyard
