enclosure = require './common/enclosure'

module.exports = (symbol, element) ->
  element.refDes = 'U'
  schematic = element.schematic
  schematic.showPinNames ?= true
  schematic.showPinNumbers ?= true
  
  enclosure symbol, element
