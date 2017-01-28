Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'C'
  icon = new icons.Capacitor(symbol, element)

  twoSided symbol, element, icon

  [icon.width, icon.height]
