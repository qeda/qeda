module.exports = (symbol, element) ->
  element.refDes = 'S'
  schematic = element.schematic
  settings = symbol.settings

  if element.pins.length > 2 then schematic.showPinNumbers = true

  step = 5
  pinLength = settings.pinLenght ? 5

  left = symbol.left
  right = symbol.right
  top = symbol.top
  bottom = symbol.bottom
  pins = element.pins

  width = 20
  height = (Math.max(left.length, right.length) + 1) * step
  if height < 10 then height = 10

  symbol
    .attribute 'refDes',
      x: 0
      y: -settings.fontSize.refDes - 2
      halign: 'center'
      valign: 'bottom'
    .attribute 'name',
      x: 0
      y: -1
      halign: 'center'
      valign: 'bottom'
    .lineWidth settings.lineWidth.thick

  if schematic.enclosure
    symbol.rectangle -width/2, 0, width/2, height, 'foreground'

  w = 10
  h = 8
  r = 1
  cy = height/2
  symbol
    .circle -w/2 + r, cy + h/2 - r, r
    .circle w/2 - r, cy + h/2 - r, r
    .line -w/2, cy, w/2, height/2
    .line 0, cy, 0, cy - h/2

  y = step
  for i in left
    pin = pins[i]
    pin.length = pinLength
    pin.orientation = 'right'
    pin.x = -width/2 - pinLength
    pin.y = y
    y += step
    symbol.pin pin

  y = step
  for i in right
    pin = pins[i]
    pin.length = pinLength
    pin.orientation = 'left'
    pin.x = width/2 + pinLength
    pin.y = y
    y += step
    symbol.pin pin

  x = -step * bottom.length/2 + step/2
  for i in bottom
    pin = pins[i]
    pin.length = pinLength
    pin.orientation = 'top'
    pin.x = x
    pin.y = height + pinLength
    x += step
    symbol.pin pin
