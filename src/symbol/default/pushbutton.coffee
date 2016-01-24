enclosure = require './common/enclosure'

drawIcon = (symbol, width, height) ->
  r = 1
  symbol
    .circle -width/2 + r, height/2 - r, r
    .circle width/2 - r, height/2 - r, r
    .line -width/2, 0, width/2, 0
    .line 0, 0, 0, 0 - height/2

module.exports = (symbol, element) ->
  element.refDes = 'S'
  schematic = element.schematic
  settings = symbol.settings

  iconWidth = 10
  iconHeight = 8

  if element.pins.length > 2 # With enclosure
    schematic.showPinNumbers = true
    symbol.minimumWidth = iconWidth
    symbol.minimumHeight = iconHeight
    enclosure symbol, element
  else # Simple symbol
    width = iconWidth
    height = iconHeight
    pinLength = settings.pinLenght ? 5
    symbol
      .attribute 'refDes',
        x: 0
        y: -height/2 - 1
        halign: 'center'
        valign: 'bottom'
      .attribute 'name',
        x: 0
        y: height/2 + 1
        halign: 'center'
        valign: 'bottom'
      .pin
        number: 1
        name: 1
        x: -width/2 - pinLength
        y: height/2 - 1
        length: pinLength
        orientation: 'right'
        type: 'passive'
      .pin
        number: 2
        name: 2
        x: width/2 + pinLength
        y: height/2 - 1
        length: pinLength
        orientation: 'left'
        type: 'passive'
      .lineWidth settings.lineWidth.thick

  drawIcon symbol, iconWidth, iconHeight
