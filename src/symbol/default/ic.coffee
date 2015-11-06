intersects = (s1, s2) ->
  a1 = (s1[0] >= s2[0]) and (s1[0] <= s2[1])
  a2 = (s1[1] >= s2[0]) and (s1[1] <= s2[1])
  a3 = (s2[0] >= s1[0]) and (s2[0] <= s1[1])
  a4 = (s2[1] >= s1[0]) and (s2[1] <= s1[1])
  a1 or a2 or a3 or a4

module.exports = (symbol) ->
  settings = symbol.settings

  step = 2
  pinLength = settings.pinLenght ? 4

  left = symbol.left
  right = symbol.right
  top = symbol.top
  bottom = symbol.bottom
  pins = symbol.element.pins

  width = step * (Math.max(top.length, bottom.length) + 1)
  height = step * (Math.max(left.length, right.length) + 1)
  space = settings.space.pinName

  # Attributes
  symbol.addAttribute 'refDes',
    x: 0
    y: -settings.fontSize.refDes - 1
    halign: 'left'
    valign: 'bottom'

  symbol.addAttribute 'name',
    x: 0
    y: -0.5
    halign: 'left'
    valign: 'bottom'

  textWidth = symbol.element.longestAlias.length * settings.fontSize.name

  leftX = -width/2
  rightX = width/2
  topY = -height/2
  bottomY = height/2

  # Pins on the top side
  y = topY
  dx = settings.fontSize.pinName/2 + space
  topPins = []
  topRects = []
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
    topPins.push pin

    h = pin.name.length*settings.fontSize.pinName + space
    x1 = x - dx
    x2 = x + dx
    if y > (-h - space) then y = -h - space
    x += step
    topRects.push
      x1: x1,
      y1: 0,
      x2: x2,
      y2: h

  topY = Math.floor y

  # Pins on the bottom side
  y = bottomY
  bottomPins = []
  bottomRects = []
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
    bottomPins.push pin

    h = pin.name.length*settings.fontSize.pinName + space
    x1 = x - dx
    x2 = x + dx
    if y < (h + space) then y = h + space
    x += step
    bottomRects.push
      x1: x1,
      y1: -h,
      x2: x2,
      y2: 0

  bottomY = Math.ceil y

  rects = []
  for r in topRects
    r.y1 += topY
    r.y2 += topY
    rects.push r

  for r in bottomRects
    r.y1 += bottomY
    r.y2 += bottomY
    rects.push r

  # Pins on the left side
  x = leftX
  dy = settings.fontSize.pinName/2 + space
  leftPins = []
  y = -step * left.length/2 + step/2
  for i in left
    if i is '-'
      y += step
      continue
    pin = pins[i]
    unless pin? then continue
    pin.y = y
    pin.length = pinLength
    pin.orientation = 'right'
    leftPins.push pin

    w = pin.name.length*settings.fontSize.pinName + space
    y1 = y - dy
    y2 = y + dy
    # Check whether pin rectangle intersects other rectangles
    for r in rects
      if intersects [y1, y2], [r.y1, r.y2]
        x1 = r.x1 - w - space
        if x > x1 then x = x1 # Make symbol wider
    y += step

  # Align according to text
  if x > (-step*(top.length/2 + 1) - textWidth)
    x = -step*(top.length/2 + 1) - textWidth
  leftX = Math.floor x

  # Pins on the right side
  x = rightX
  rightPins = []
  y = -step * right.length/2 + step/2
  for i in right
    if i is '-'
      y += step
      continue
    pin = pins[i]
    unless pin? then continue
    pin.y = y
    pin.length = pinLength
    pin.orientation = 'left'
    rightPins.push pin

    w = pin.name.length*settings.fontSize.pinName + space
    y1 = y - dy
    y2 = y + dy
    # Check whether pin rectangle intersects other rectangles
    for r in rects
      if intersects [y1, y2], [r.y1, r.y2]
        x2 = r.x2 + w + space
        if x < x2 then x = x2 # Make symbol wider
    y += step

  rightX = Math.ceil x

  # Update box size
  width = rightX - leftX
  height = bottomY - topY

  # Box
  y = topY
  symbol.addRectangle
    x: 0
    y: 0
    width: width
    height: height
    fill: 'foreground'

  for pin in leftPins
    pin.x = -pinLength
    pin.y -= topY
    symbol.addPin pin

  for pin in rightPins
    pin.x = width + pinLength
    pin.y -= topY
    symbol.addPin pin

  for pin in topPins
    pin.x -= leftX
    pin.y = -pinLength
    symbol.addPin pin

  for pin in bottomPins
    pin.x -= leftX
    pin.y = height + pinLength
    symbol.addPin pin
