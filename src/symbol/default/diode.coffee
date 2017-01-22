enclosure = require './common/enclosure'
Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, styleIcons) ->
  element.refDes = 'D'
  schematic = element.schematic
  settings = symbol.settings

  pins = element.pins
  numbers = Object.keys pins
  decorated = numbers.length > 2

  schematic.showPinNames ?= false

  icon = if styleIcons? then new styleIcons.Diode(symbol, element) else new Icons.Diode(symbol, element)

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
