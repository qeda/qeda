module.exports = (symbol) ->
  part = symbol.part
  settings = symbol.settings

  step = 2
  pinLength = settings.pinLenght ? 4

  left = symbol.left
  right = symbol.right
  top = symbol.top
  bottom = symbol.bottom
  pins = symbol.element.pins

  # Attributes
  symbol.addAttribute 'refDes',
    x: 0
    y: -0.5
    halign: 'center'
    valign: 'bottom'

  symbol.addAttribute 'name',
    x: 0
    y: 0.5
    halign: 'center'
    valign: 'top'

  width = step * (Math.max(top.length, bottom.length) + 2)
  height = step * (Math.max(left.length, right.length) + 2)

  # Pins on the left side
  leftPins = []
  leftTextWidth = 0
  if top.length > 0 # Center aligned symbol
    y = -step * left.length/2 + step/2
  else # Top aligned symbol
    y = Math.ceil(settings.fontSize.name + step)
  for i in left
    if i is '-'
      y += step
      continue
    pin = pins[i]
    unless pin? then continue
    #pin.x = -width/2 - pinLength
    pin.y = y
    pin.length = pinLength
    pin.orientation = 'right'
    if pin.name.length > leftTextWidth then leftTextWidth = pin.name.length
    leftPins.push pin
    #symbol.addPin pin
    y += step
  leftTextWidth *= settings.fontSize.pinName
  leftTextWidth += settings.space.pinName

  # Pins on the right side
  rightPins = []
  rightTextWidth = 0
  if top.length > 0 # Center aligned symbol
    y = -step * right.length/2 + step/2
  else # Top aligned symbol
    y = Math.ceil(settings.fontSize.name + step)
  for i in right
    if i is '-'
      y += step
      continue
    pin = pins[i]
    unless pin? then continue
    #pin.x = width/2 + pinLength
    pin.y = y
    pin.length = pinLength
    pin.orientation = 'left'
    if pin.name.length > rightTextWidth then rightTextWidth = pin.name.length
    rightPins.push pin
    #symbol.addPin pin
    y += step
  rightTextWidth *= settings.fontSize.pinName
  rightTextWidth += settings.space.pinName

  nameTextWidth = Math.ceil(symbol.element.name.length*settings.fontSize.name)

  if top.length > 0 # Center aligned symbol
    width = Math.max width, (leftTextWidth + nameTextWidth + rightTextWidth)
  else # Top aligned symbol
    width = Math.max width, nameTextWidth, (leftTextWidth + rightTextWidth)

  symbol.addRectangle
    x: -width/2
    y: -height/2
    width: width
    height: height
    fill: 'foreground'

  for pin in leftPins
    pin.x = -width/2 - pinLength
    symbol.addPin pin

  for pin in rightPins
    pin.x = width/2 + pinLength
    symbol.addPin pin

  # Pins on the top side
  x = -step * top.length/2 + step/2
  for i in top
    if i is '-'
      x += step
      continue
    pin = pins[i]
    unless pin? then continue
    pin.x = x
    pin.y = -height/2 - pinLength
    pin.length = pinLength
    pin.orientation = 'down'
    symbol.addPin pin
    x += step

  # Pins on the bottom side
  x = -step * bottom.length/2 + step/2
  for i in bottom
    if i is '-'
      x += step
      continue
    pin = pins[i]
    unless pin? then continue
    pin.x = x
    pin.y = height/2 + pinLength
    pin.length = pinLength
    pin.orientation = 'up'
    symbol.addPin pin
    x += step
