module.exports = (symbol, element) ->
  element.refDes = '#BR'
  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  pinLength = settings.pinLength ? 2.5
  pinLength = symbol.alignToGrid(pinLength, 'ceil')

  symbol
    .attribute 'refDes',
      x: 0
      y: -settings.space.attribute
      halign: 'center'
      valign: 'bottom'
      visible: false
    .attribute 'name',
      x: 0
      y: settings.space.attribute
      halign: 'center'
      valign: 'top'
      visible: false
    .pin
      number: 1
      name: 1
      x: -pinLength
      y: 0
      length: pinLength
      orientation: 'right'
      passive: true
    .pin
      number: 2
      name: 2
      x: pinLength
      y: 0
      length: pinLength
      orientation: 'left'
      passive: true
