calculator = require './common/calculator'
copper = require './common/copper'
silkscreen = require './common/silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  pattern.name ?= element.name.toUpperCase()

  if housing.holeDiameter?
    housing.padDiameter ?= calculator.padDiameter pattern, housing, housing.holeDiameter
    housing.padWidth ?= housing.padDiameter
    housing.padHeight ?= housing.padDiameter
    pad =
      type: 'through-hole'
      hole: housing.holeDiameter
      shape: 'circle'
      layer: ['topCopper', 'topMask', 'intCopper', 'bottomCopper', 'bottomMask']
  else
    housing.padWidth ?= housing.padDiameter
    housing.padHeight ?= housing.padDiameter
    if housing.nopaste?
      pad =
        type: 'smd'
        shape: 'circle'
        layer: ['topCopper', 'topMask']
    else
      pad =
        type: 'smd'
        shape: 'circle'
        layer: ['topCopper', 'topMask', 'topPaste']

  pad.width = housing.padWidth
  pad.height = housing.padHeight
  pad.shape = 'circle'
  pad.x = 0
  pad.y = 0
  pad.property = 'testpoint'
  pattern.pad 1, pad

  if housing.mask?
    pattern.pads[0].mask = housing.mask
  else
    copper.mask pattern

  courtyard =  housing.courtyard ? { M: 0.5, N: 0.25, L: 0.12 }[settings.densityLevel]
  pad = pattern.pads[0]
  pad.clearance = housing.padClearance || pad.mask + courtyard

  if !housing.nosilk?
    r = Math.max(housing.padWidth, housing.padHeight) / 2
    r += Math.max(settings.clearance.padToSilk, pad.mask + settings.lineWidth.silkscreen/2) + settings.lineWidth.silkscreen/2
    silkscreen
      .preamble pattern, housing
      .attribute 'value',
        text: pattern.name
        x: 0
        y: 0
        halign: 'center'
        valign: 'center'
      .circle 0, 0, r
    if pad.type is 'through-hole'
      pattern
        .layer 'bottomSilkscreen'
        .circle 0, 0, r

  r = Math.max(housing.padWidth, housing.padHeight) / 2
  r += Math.max(pad.mask + courtyard, pad.clearance)
  pattern
    .layer 'topCourtyard'
    .lineWidth pattern.settings.lineWidth.courtyard
    .circle 0, 0, r
