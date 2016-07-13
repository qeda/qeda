module.exports = (symbol, element) ->
  element.refDes = 'MH'
  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  r = 2.5
  d = 1.5
  pinLength = settings.pinLength ? 2.5
  pinLength = symbol.alignToGrid(pinLength + r, 'ceil') - r

  symbol
    .attribute 'refDes',
      x: 0
      y: -r - settings.space.attribute
      halign: 'center'
      valign: 'bottom'
    .attribute 'name',
      x: r + settings.space.attribute
      y: 0
      halign: 'left'
      valign: 'center'
      visible: false
    .pin
      number: 1
      name: 1
      x: 0
      y: r + pinLength
      length: pinLength
      orientation: 'up'
      passive: true
    .lineWidth settings.lineWidth.thick
    .circle 0, 0, r, settings.fill
    .circle 0, 0, r - d, settings.fill

  [2*r, 2*r]
