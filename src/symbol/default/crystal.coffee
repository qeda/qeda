enclosure = require './common/enclosure'
Icons = require './common/icons'

module.exports = (symbol, element) ->
  element.refDes = 'Y'
  schematic = element.schematic
  settings = symbol.settings
  pins = element.pins
  pinGroups = element.pinGroups

  icon = new Icons.Crystal(symbol, element)

  if element.pins.length > 2 # With enclosure
    schematic.showPinNumbers = true
    enclosure symbol, element, icon
  else
    width = icon.width
    height = icon.height
    pinLength = settings.pinLength ? 2.5
    pinLength = (2*symbol.alignToGrid(width/2 + pinLength, 'ceil') - width) / 2
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
        y: 0
        length: pinLength
        orientation: 'right'
        passive: true
      .pin
        number: 2
        name: 2
        x: width/2 + pinLength
        y: 0
        length: pinLength
        orientation: 'left'
        passive: true
    icon.draw 0, 0
