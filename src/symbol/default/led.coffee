diode = require './diode'

module.exports = (symbol, element) ->
  schematic = element.schematic
  schematic.led = true

  diode symbol, element
