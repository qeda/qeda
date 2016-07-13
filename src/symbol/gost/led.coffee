module.exports = (symbol, element) ->
  element.refDes = 'HL'
  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  width = 4
  height = 5
  r = 6
  pinLength = settings.pinLength ? 2.5
  pinLength = symbol.alignToGrid(r + pinLength, 'ceil') - r

  space = 1
  d = 1.5
  len = 3
  arrowWidth = 1

  x = Math.round(r / Math.sqrt(2)) + space
  y = -x
  x1 = x
  y1 = y - d
  x2 = x + d
  y2 = y

  symbol
    .attribute 'refDes',
      x: 0
      y: -r - settings.space.attribute
      halign: 'center'
      valign: 'bottom'
    .attribute 'name',
      x: 0
      y: r + settings.space.attribute
      halign: 'center'
      valign: 'top'
    .pin
      number: 1
      name: 'C'
      x: r + pinLength
      y: 0
      length: pinLength
      orientation: 'left'
      passive: true
    .pin
      number: 2
      name: 'A'
      x: -r - pinLength
      y: 0
      length: pinLength
      orientation: 'right'
      passive: true
    .lineWidth settings.lineWidth.thick
    .polyline -width/2, -height/2, width/2, 0, -width/2, height/2, -width/2, -height/2
    .line width/2, -height/2, width/2, height/2
    .line -r, 0, r, 0
    .circle 0, 0, r, settings.fill
    .line x1, y1, x1 + len, y1 - len
    .arrow x1 + len/2, y1 - len/2, x1 + len, y1 - len, arrowWidth
    .line x2, y2, x2 + len, y2 - len
    .arrow x2 + len/2, y2 - len/2, x2 + len, y2 - len, arrowWidth

  [width, height]
