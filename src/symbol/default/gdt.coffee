Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'GT'
  symbol.orientations = [0, 90, 180, 270]
  icon = new icons.GDT(symbol, element, element.schematic.ground)

  if element.schematic.ground
    unless Object.keys(element.pinGroups).length
      element.pins[1] = { name: 'L', number: 1 }
      element.pins[3] = { name: 'R', number: 3 }
      element.pins[2] = { name: 'B', number: 2 }
      element.pinGroups['L'] = [1]
      element.pinGroups['R'] = [3]
      element.pinGroups['B'] = [2]
    else
      console.log element.pins, element.pinGroups

  twoSided symbol, element, icon, 'L', 'R', if element.schematic.ground then 'B' else ''

  [icon.width, icon.height]
