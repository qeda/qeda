enclosure = require './common/enclosure'

icon = Object.create
  width: 10
  height: 8
  lineWidth: 0
  draw: (symbol, x, y) ->
    r = 1
    symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      .circle -@width/2 + r, @height/2 - r, r
      .circle @width/2 - r, @height/2 - r, r
      .line -@width/2, 0, @width/2, 0
      .line 0, 0, 0, -@height/2
      .center 0, 0 # Restore default center point

module.exports = (symbol, element) ->
  element.refDes = 'S'
  schematic = element.schematic
  settings = symbol.settings

  icon.lineWidth = settings.lineWidth.thick

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
      .icon 0, 0, icon
