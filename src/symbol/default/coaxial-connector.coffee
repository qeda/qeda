Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'J'
  symbol.orientations = [0, 90, 180, 270]
  icon = new icons.CoaxialConnector(symbol, element)

  twoSided symbol, element, icon, 'C', (if element.schematic.switch then 'R' else ''), 'GND'

  [icon.width, icon.height]
