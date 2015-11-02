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
  space = settings.space.pinName

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
    pin.y = y
    pin.length = pinLength
    pin.orientation = 'right'
    if pin.name.length > leftTextWidth then leftTextWidth = pin.name.length
    leftPins.push pin
    y += step
  leftTextWidth *= settings.fontSize.pinName

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
    pin.y = y
    pin.length = pinLength
    pin.orientation = 'left'
    if pin.name.length > rightTextWidth then rightTextWidth = pin.name.length
    rightPins.push pin
    y += step
  rightTextWidth *= settings.fontSize.pinName

  # Pins on the top side
  topPins = []
  topTextWidth = step*(top.length - 1) + settings.fontSize.pinName
  topTextHeight = 0
  x = -step * top.length/2 + step/2
  for i in top
    if i is '-'
      x += step
      continue
    pin = pins[i]
    unless pin? then continue
    pin.x = x
    pin.length = pinLength
    pin.orientation = 'down'
    if pin.name.length > topTextHeight then topTextHeight = pin.name.length
    topPins.push pin
    x += step
  topTextHeight *= settings.fontSize.pinName

  # Pins on the bottom side
  bottomPins = []
  bottomTextWidth = step*(bottom.length - 1) + settings.fontSize.pinName
  bottomTextHeight = 0
  x = -step * bottom.length/2 + step/2
  for i in bottom
    if i is '-'
      x += step
      continue
    pin = pins[i]
    unless pin? then continue
    pin.x = x
    pin.length = pinLength
    pin.orientation = 'up'
    if pin.name.length > bottomTextHeight then bottomTextHeight = pin.name.length
    bottomPins.push pin
    x += step
  bottomTextHeight *= settings.fontSize.pinName

  textWidth = symbol.element.name.length * settings.fontSize.name
  textWidth = Math.ceil(textWidth / 2) * 2 # Make width even

  if top.length > 0 # Center aligned symbol
    width = Math.max width, (leftTextWidth + textWidth + rightTextWidth + space)
  else # Top aligned symbol
    width = Math.max width, textWidth, (leftTextWidth + rightTextWidth + space)
  width += 2*space

  textHeight = settings.fontSize.refDes + settings.fontSize.name + 1
  height = Math.max height, (topTextHeight + textHeight + bottomTextHeight + 2*space)
  if topTextWidth > textWidth
    height += topTextHeight
  if bottomTextWidth > textWidth
    height += bottomTextHeight

  width = Math.ceil(width / 2) * 2 # Make width even
  height = Math.ceil(height / 2) * 2 # Make height even

  y = 0
  if top.length > 0 then y = -height/2 # Center aligned symbol

  x = -width/2
  if left.length is 0
    x = -textWidth/2
  if right.length is 0
    x = textWidth/2 - width

  symbol.addRectangle
    x: x
    y: y
    width: width
    height: height
    fill: 'foreground'

  for pin in leftPins
    pin.x = x - pinLength
    symbol.addPin pin

  x += width
  for pin in rightPins
    pin.x = x + pinLength
    symbol.addPin pin

  for pin in topPins
    pin.y = y - pinLength
    symbol.addPin pin

  y += height
  for pin in bottomPins
    pin.y = y + pinLength
    symbol.addPin pin
