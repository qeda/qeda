Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'R'
  symbol.orientations = [0, 90, 180, 270]
  icon = new icons.Resistor(symbol, element)

  twoSided symbol, element, icon

  [icon.width, icon.height]
