enclosure = require './common/enclosure'

icon = Object.create
  width: 10
  height: 8
  draw: (symbol, x, y) ->
    r = 1
    symbol
      .circle x - @width/2 + r, y + @height/2 - r, r
      .circle x + @width/2 - r, y + @height/2 - r, r
      .line x - @width/2, y, x + @width/2, y
      .line x, y, x, y - @height/2

module.exports = (symbol, element) ->
  element.refDes = 'S'
  schematic = element.schematic
  settings = symbol.settings

  if element.pins.length > 2 # With enclosure
    schematic.showPinNumbers = true
    schematic.showPinNames = true
    enclosure symbol, element, icon
  else # Simple symbol
    width = icon.width
    height = icon.weight
    pinLength = settings.pinLength ? 5
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
      .icon 0, 0, icon
