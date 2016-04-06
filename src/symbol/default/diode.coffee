Icons = require './common/icons'

module.exports = (symbol, element, styleIcons) ->
  element.refDes = 'D'
  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  icon = if styleIcons? then new styleIcons.Diode(symbol, element) else new Icons.Diode(symbol, element)

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
      name: 'C'
      x: width/2 + pinLength
      y: 0
      length: pinLength
      orientation: 'left'
      passive: true
    .pin
      number: 2
      name: 'A'
      x: -width/2 - pinLength
      y: 0
      length: pinLength
      orientation: 'right'
      passive: true

  icon.draw 0, 0

  [width, height]
