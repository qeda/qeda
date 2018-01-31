Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'L'
  symbol.orientations = [0, 90, 180, 270]
  icon = new icons.Inductor(symbol, element)

  twoSided symbol, element, icon

  [icon.width, icon.height]
