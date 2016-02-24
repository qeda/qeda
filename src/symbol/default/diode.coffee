module.exports = (symbol, element) ->
  element.refDes = 'D'
  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  pinLength = settings.pinLength ? 2.5
  width = 5
  height = 5
  pinLength = (2*symbol.alignToGrid(width/2 + pinLength, 'ceil') - width) / 2

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
    .lineWidth settings.lineWidth.thick
    .polyline -width/2, -height/2, width/2, 0, -width/2, height/2, -width/2, -height/2
    .line width/2, -height/2, width/2, height/2
  if schematic.schottky
    d = 1
    symbol
      .moveTo width/2, height/2
      .lineTo width/2 - d, height/2
      .lineTo width/2 - d, height/2 - d
      .moveTo width/2, -height/2
      .lineTo width/2 + d, -height/2
      .lineTo width/2 + d, -height/2 + d
  else if schematic.zener
    d = 1
    symbol
      .line width/2, -height/2, width/2 - d, -height/2 - d
      .line width/2, height/2, width/2 + d, height/2 + d
