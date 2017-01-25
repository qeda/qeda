enclosure = require './common/enclosure'
Icons = require './common/icons'
twoSided = require './common/two-sided'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'R'
  schematic = element.schematic
  settings = symbol.settings

  pins = element.pins
  schematic.showPinNames ?= false

  icon = new icons.Resistor(symbol, element)

  groups = symbol.part ? element.pinGroups
  for k, v of groups
    k = k.toUpperCase()
    if k.match /^L/
      left = v.map((e) => pins[e])
    else if k.match /^R/
      right = v.map((e) => pins[e])
    else if k.match /^NC/
      nc = v.map((e) => pins[e])
    else if k is '' # Root group
      continue
    else
      needEnclosure = true

  left ?= [
    name: 'L'
    number: 1
  ]

  right ?= [
    name: 'R'
    number: 2
  ]

  if needEnclosure
    schematic.showPinNames = true
    schematic.showPinNumbers = true
    enclosure symbol, element, icon
  else
    twoSided symbol, element, icon, left, right, nc

  [icon.width, icon.height]
