Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'R'
  icon = new icons.Resistor(symbol, element)

  twoSided symbol, element, icon

  [icon.width, icon.height]
