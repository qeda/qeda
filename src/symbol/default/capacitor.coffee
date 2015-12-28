module.exports = (symbol, element) ->
  element.refDes = 'C'
  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  pinLength = settings.pinLenght ? 2.5
  width = 1
  height = 3.2

  symbol
    .attribute 'refDes',
      x: 0
      y: -height/2 - 0.5
      halign: 'center'
      valign: 'bottom'
    .attribute 'name',
      x: 0
      y: height/2 + 0.5
      halign: 'center'
      valign: 'top'
    .pin
      number: 1
      name: 1
      x: -width/2 - pinLength
      y: 0
      length: pinLength
      orientation: 'right'
      type: 'passive'
    .pin
      number: 2
      name: 2
      x: width/2 + pinLength
      y: 0
      length: pinLength
      orientation: 'left'
      type: 'passive'
    .lineWidth settings.lineWidth.default
    .line -width/2, -height/2, -width/2, height/2
    .line width/2, -height/2, width/2, height/2
