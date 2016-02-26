module.exports = (symbol, element) ->
  element.refDes = 'C'
  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  pinLength = settings.pinLength ? 4.25
  width = 1.5
  height = 8

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
  if schematic.polarized
    d = 1
    x = -width/2 - 2*d
    y = -height/4
    r = 6*width
    a = 180 * Math.asin(height/(2*r)) / Math.PI
    symbol
      .arc r + width/2, 0, r, 180 - a, 180 + a
      .lineWidth settings.lineWidth.thin
      .line x - d, y, x + d, y
      .line x, y - d, x, y + d
  else
    symbol.line width/2, -height/2, width/2, height/2
