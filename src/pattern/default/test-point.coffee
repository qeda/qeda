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

  copper.mask pattern

  r = Math.max(housing.padWidth, housing.padHeight) / 2
  r += settings.clearance.padToSilk + settings.lineWidth.silkscreen/2
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
