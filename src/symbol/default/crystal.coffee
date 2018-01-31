Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'Y'
  symbol.orientations = [0, 90, 180, 270]
  icon = new icons.Crystal(symbol, element)

  twoSided symbol, element, icon

  [icon.width, icon.height]
