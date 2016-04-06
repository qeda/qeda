Icons = require './common/icons'

module.exports = (symbol, element) ->
  element.refDes = 'VD'
  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= true

  icon = new Icons.Diode(symbol, element)

  space = icon.width/2
  width = 2*icon.width + 4*space
  width = 2*symbol.alignToGrid(width/2, 'ceil')
  height = icon.height + 2*space
  height = 2*symbol.alignToGrid(height/2, 'ceil')

  pinLength = settings.pinLength ? 5
  pinLength = symbol.alignToGrid(pinLength, 'ceil')

  pins = element.pins
  numbers = Object.keys pins
  left = pins[numbers[0]]
  middle = pins[numbers[1]]
  right = pins[numbers[2]]

  symbol
    .attribute 'refDes',
      x: 0
      y: -height/2 - settings.space.attribute
      halign: 'center'
      valign: 'bottom'
    .attribute 'name',
      x: settings.space.attribute
      y: height/2 + settings.space.attribute
      halign: 'left'
      valign: 'top'
    .pin
      number: left.number
      name: left.name
      x: -width/2 - pinLength
      y: 0
      length: pinLength
      orientation: 'right'
      passive: true
    .pin
      number: middle.number
      name: middle.name
      x: 0
      y: height/2 + pinLength
      length: pinLength
      orientation: 'up'
      passive: true
    .pin
      number: right.number
      name: right.name
      x: width/2 + pinLength
      y: 0
      length: pinLength
      orientation: 'left'
      passive: true

  x1 = -icon.width - space
  x2 = icon.width + space
  icon.draw x1, 0
  icon.draw x2, 0, true
  symbol
    .rectangle -width/2, -height/2, width/2, height/2
    .line -width/2, 0, x1 - icon.width/2, 0
    .line x1 + icon.width/2, 0, x2 - icon.width/2, 0
    .line x2 + icon.width/2, 0, width/2, 0
    .line 0, 0, 0, height/2

  [width, height]
