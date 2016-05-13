module.exports = (symbol, element) ->
  element.refDes = 'C'
  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  width = 1.5
  height = 8
  pinLength = settings.pinLength ? 4.25
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
    .lineWidth settings.lineWidth.thick
    .line -width/2, -height/2, -width/2, height/2
    .line width/2, -height/2, width/2, height/2

  if schematic.polarized
    d = 1
    x = -width/2 - 2*d
    y = -height/4
    symbol
      .lineWidth settings.lineWidth.thin
      .line x - d, y, x + d, y
      .line x, y - d, x, y + d
