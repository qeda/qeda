enclosure = require './common/enclosure'
Icons = require './common/icons'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'S'
  schematic = element.schematic
  settings = symbol.settings
  pins = element.pins
  icon = new icons.Pushbutton(symbol, element)

  if element.pins.length > 2 # With enclosure
    schematic.showPinNumbers = true
    schematic.showPinNames = true
    for k, v of pins
      if pins[k].nc isnt true
        pins[k].passive = true
    enclosure symbol, element, icon
  else # Simple symbol
    width = icon.width
    height = icon.height
    pinLength = settings.pinLength ? 5
    symbol
      .attribute 'refDes',
        x: 0
        y: -height/2 - settings.space.attribute
        halign: 'center'
        valign: 'bottom'
      .attribute 'name',
        x: 0
        y: height/2 + settings.space.attribute
        halign: 'center'
        valign: 'top'
      .pin
        number: 1
        name: 1
        x: -width/2 - pinLength
        y: height/2 - 1
        length: pinLength
        orientation: 'right'
        passive: true
      .pin
        number: 2
        name: 2
        x: width/2 + pinLength
        y: height/2 - 1
        length: pinLength
        orientation: 'left'
        passive: true
    icon.draw 0, 0
