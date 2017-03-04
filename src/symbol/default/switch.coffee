Icons = require './common/icons'
enclosure = require './common/enclosure'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'SW'
  schematic = element.schematic
  icon = new icons.Switch(symbol, element)

  pins = element.pins
  for k, v of pins
    if pins[k].nc isnt true
      pins[k].passive = true

  schematic.showPinNames ?= true
  schematic.showPinNumbers ?= true
  enclosure symbol, element, icon

  [icon.width, icon.height]
