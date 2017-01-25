enclosure = require './common/enclosure'
Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'D'
  schematic = element.schematic
  settings = symbol.settings
  pins = element.pins
  icon = new icons.Diode(symbol, element)

  schematic.showPinNames ?= false

  groups = symbol.part ? element.pinGroups
  for k, v of groups
    k = k.toUpperCase().replace('K', 'C')
    if k.match /^A/
      anode = v.map((e) => pins[e])
    else if k.match /^C/
      cathode = v.map((e) => pins[e])
    else if k.match /^NC/
      nc = v.map((e) => pins[e])
    else if k is '' # Root group
      continue
    else
      needEnclosure = true

  anode ?= [
    name: 'A'
    number: 2
  ]

  cathode ?= [
    name: 'C'
    number: 1
  ]

  if needEnclosure
    schematic.showPinNames = true
    schematic.showPinNumbers = true
    enclosure symbol, element, icon
  else
    twoSided symbol, element, icon, anode, cathode, nc

  [icon.width, icon.height]
