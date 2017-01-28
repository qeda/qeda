Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'D'
  icon = new icons.Diode(symbol, element)

  twoSided symbol, element, icon, 'A', 'C'

  [icon.width, icon.height]
