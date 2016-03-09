assembly = require './common/assembly'
calculator = require './common/calculator'
copper = require './common/copper'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  #settings = pattern.settings
  pattern.name ?= element.name.toUpperCase()

  if housing.drillDiameter?
    pad =
      type: 'through-hole'
      drill: housing.drillDiameter
      width: housing.padWidth
      height: housing.padHeight
      shape: 'rectangle'
      layer: ['topCopper', 'topMask', 'topPaste', 'bottomCopper', 'bottomMask', 'bottomPaste']
  else
    pad =
      type: 'smd'
      width: housing.padWidth
      height: housing.padHeight
      shape: 'rectangle'
      layer: ['topCopper', 'topMask', 'topPaste']

  points = copper.parsePosition housing.padPosition
  for p, i in points
    pad.x = p.x
    pad.y = p.y
    pattern.pad i + 1, pad
    if housing.drillDiameter?
      pad.shape = 'circle'

  silkscreen.body pattern, housing
  assembly.body pattern, housing
  courtyard.body pattern, housing
