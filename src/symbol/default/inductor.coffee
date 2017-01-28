Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'L'
  icon = new icons.Inductor(symbol, element)

  twoSided symbol, element, icon

  [icon.width, icon.height]
