module.exports = (symbol, element) ->
  element.refDes = 'L'
  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  pinLength = settings.pinLength ? 2.5
  r = 2.5

  symbol
    .attribute 'refDes',
      x: 0
      y: -r - settings.space.attribute
      halign: 'center'
      valign: 'bottom'
    .attribute 'name',
      x: 0
      y: settings.space.attribute
      halign: 'center'
      valign: 'top'
    .pin
      number: 1
      name: 1
      x: -4*r - pinLength
      y: 0
      length: pinLength
      orientation: 'right'
      passive: true
    .pin
      number: 2
      name: 2
      x: 4*r + pinLength
      y: 0
      length: pinLength
      orientation: 'left'
      passive: true
    .lineWidth settings.lineWidth.thick

  x = -3*r
  for i in [0..3]
    symbol.arc x, 0, r, 180, 0
    x += 2*r
