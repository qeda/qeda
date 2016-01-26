module.exports = (symbol, element) ->
  element.refDes = 'C'
  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  pinLength = settings.pinLenght ? 4.25
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
    .line width/2, -height/2, width/2, height/2
