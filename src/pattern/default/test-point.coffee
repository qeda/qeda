calculator = require './common/calculator'
copper = require './common/copper'
silkscreen = require './common/silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  pattern.name ?= element.name.toUpperCase()

  if housing.drillDiameter?
    housing.padDiameter ?= calculator.padDiameter pattern, housing, housing.drillDiameter
    housing.padWidth ?= housing.padDiameter
    housing.padHeight ?= housing.padDiameter
    pad =
      type: 'through-hole'
      drill: housing.drillDiameter
      shape: 'circle'
      layer: ['topCopper', 'topMask', 'topPaste', 'bottomCopper', 'bottomMask', 'bottomPaste']
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
