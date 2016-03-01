sprintf = require('sprintf-js').sprintf
assembly = require './common/assembly'
calculator = require './common/calculator'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'
sop = require './sop'
log = require '../../qeda-log'

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

  if (housing.leadCount % 2) is 0 # Even
    sop pattern, element
  else # Odd
    # Calculate pad dimensions according to IPC-7351
    padParams = calculator.sop pattern, housing

    switch housing.leadCount
      when 3
        leftCount = 2
        leftPitch = housing.pitch * 2
        rightCount = 1
        rightPitch = housing.pitch
      when 5
        leftCount = 3
        leftPitch = housing.pitch
        rightCount = 2
        rightPitch = housing.pitch * 2
      else log.error "Wrong lead count (#{housing.leadCount})"

    pad =
      type: 'smd'
      shape: 'rectangle'
      width: padParams.width
      height: padParams.height
      layer: ['topCopper', 'topMask', 'topPaste']

    # Pads on the left side
    pad.x = -padParams.distance / 2
    y = -leftPitch * (leftCount/2 - 0.5)
    for i in [1..leftCount]
      pad.y = y
      pattern.pad i, pad
      y += leftPitch

    # Pads on the right side
    pad.x = padParams.distance / 2
    y = rightPitch * (rightCount/2 - 0.5)
    for i in [1..rightCount]
      pad.y = y
      pattern.pad leftCount + i, pad
      y -= rightPitch

    silkscreen.dual pattern, housing
    assembly.polarized pattern, housing
    courtyard.dual pattern, housing, padParams.courtyard
