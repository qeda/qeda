enclosure = require './common/enclosure'
Icon = require './common/icon'

module.exports = (symbol, element) ->
  element.refDes = 'T'

  schematic = element.schematic
  schematic.showPinNames ?= true
  schematic.showPinNumbers ?= true

  pins = element.pins
  for k, v of pins
    if pins[k].nc isnt true
      pins[k].passive = true

  enclosure symbol, element
