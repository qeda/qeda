enclosure = require './common/enclosure'
Icon = require './common/icon'

class CrystalIcon extends Icon
  constructor: (symbol, element) ->
    @width = 6
    @height = 8
    super symbol, element

  draw: (x, y) ->
    settings = @symbol.settings
    gap = 1.5
    d = 2
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      .rectangle -@width/2 + gap, -@height/2, @width/2 - gap, @height/2, settings.fill
      .line -@width/2, -@height/2 + d, -@width/2, @height/2 - d
      .line @width/2, -@height/2 + d, @width/2, @height/2 - d
      .center 0, 0 # Restore default center point

module.exports = (symbol, element) ->
  element.refDes = 'Y'
  schematic = element.schematic
  settings = symbol.settings
  pins = element.pins
  pinGroups = element.pinGroups

  icon = new CrystalIcon(symbol, element)

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
