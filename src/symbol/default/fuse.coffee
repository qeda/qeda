module.exports = (symbol, element) ->
  element.refDes = 'F'
  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  width = 10
  height = 4
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
    .lineWidth settings.lineWidth.thick
    .rectangle -width/2, -height/2, width/2, height/2, settings.fill
    .line -width/2, 0, width/2, 0

  [width, height]
