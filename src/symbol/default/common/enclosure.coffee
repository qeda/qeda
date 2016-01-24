module.exports = (symbol, element) ->
  schematic = element.schematic
  settings = symbol.settings

  step = 5
  pinLength = settings.pinLenght ? 10

  left = symbol.left
  right = symbol.right
  top = symbol.top
  bottom = symbol.bottom
  pins = element.pins

  width = step * (Math.max(top.length, bottom.length) + 1)
  height = step * (Math.max(left.length, right.length) + 1)
  space = settings.space.pin
  width = Math.max width, symbol.minimumWidth + 2*space
  height = Math.max height, symbol.minimumHeight + 2*space

  left = symbol.left
  right = symbol.right
  top = symbol.top
  bottom = symbol.bottom
  pins = element.pins

  textX = 0
  textHAlign = 'center'

  if top.length > 0
    textX = top[0].x - space
    textHAlign = 'right'

  symbol
    .attribute 'refDes',
      x: textX
      y: -height/2 - settings.fontSize.refDes - 2
      halign: textHAlign
      valign: 'bottom'
    .attribute 'name',
      x: textX
      y: -height/2 - 1
      halign: textHAlign
      valign: 'bottom'
    .lineWidth settings.lineWidth.thick
    .rectangle -width/2, -height/2, width/2, height/2, 'foreground'

  y = -step * left.length/2 + step/2
  for i in left
    pin = pins[i]
    pin.length = pinLength
    pin.orientation = 'right'
    pin.x = -width/2 - pinLength
    pin.y = y
    y += step
    symbol.pin pin

  y = -step * right.length/2 + step/2
  for i in right
    pin = pins[i]
    pin.length = pinLength
    pin.orientation = 'left'
    pin.x = width/2 + pinLength
    pin.y = y
    y += step
    symbol.pin pin

  x = -step * top.length/2 + step/2
  for i in top
    pin = pins[i]
    pin.length = pinLength
    pin.orientation = 'top'
    pin.x = x
    pin.y = -height/2 - pinLength
    x += step
    symbol.pin pin

  x = -step * bottom.length/2 + step/2
  for i in bottom
    pin = pins[i]
    pin.length = pinLength
    pin.orientation = 'top'
    pin.x = x
    pin.y = height/2 + pinLength
    x += step
    symbol.pin pin
