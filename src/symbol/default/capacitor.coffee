Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'C'
  symbol.orientations = [0, 90, 180, 270]
  if element.schematic.polarized == true
    symbol.orientations = [0, 90]
  if element.schematic.feedthrough
    icon = new icons.CapacitorFeedthrough(symbol, element)
  else
    icon = new icons.Capacitor(symbol, element)

  twoSided symbol, element, icon, 'L', 'R', if element.schematic.feedthrough then 'B' else ''

  [icon.width, icon.height]
