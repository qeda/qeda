Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'D'
  symbol.orientations = [0, 90]
  if element.schematic.zener == true
    symbol.orientations = [180, 270]
  icon = new icons.Diode(symbol, element)

  # Cathode on the right but has number 1
  element.pins[1] ?= { name: 'C', number: 1 }
  # Anode on the left but has number 2
  element.pins[2] ?= { name: 'A', number: 2 }
  element.pinGroups['C'] ?= [1]
  element.pinGroups['A'] ?= [2]
  twoSided symbol, element, icon, 'A', 'C'

  [icon.width, icon.height]
