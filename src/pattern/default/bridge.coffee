module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  pattern.name ?= element.name.toUpperCase()

  pad =
    type: 'smd'
    x: -housing.padWidth/2
    y: 0
    width: housing.padWidth
    height: housing.padHeight
    shape: 'rectangle'
    layer: ['topCopper']

  pattern.pad 1, pad
  pad.x = -pad.x
  pattern.pad 2, pad
