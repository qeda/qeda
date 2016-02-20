intersects = (s1, s2) ->
  a1 = (s1[0] >= s2[0]) and (s1[0] <= s2[1])
  a2 = (s1[1] >= s2[0]) and (s1[1] <= s2[1])
  a3 = (s2[0] >= s1[0]) and (s2[0] <= s1[1])
  a4 = (s2[1] >= s1[0]) and (s2[1] <= s1[1])
  a1 or a2 or a3 or a4

pinTextWidth = (symbol, pin, visible) ->
  if visible then symbol.textWidth(pin.name, 'pin') else 0

module.exports = (symbol, element, icon) ->
  schematic = element.schematic
  settings = symbol.settings

  step = symbol.alignToGrid 5
  pinLength = symbol.alignToGrid(settings.pinLength ? 10)

  left = symbol.left
  right = symbol.right
  top = symbol.top
  bottom = symbol.bottom
  pins = element.pins

  width = step * (Math.max(top.length, bottom.length) + 1)
  height = step * (Math.max(left.length, right.length) + 1)
  space = settings.space.pin

  # Attributes
  symbol
    .attribute 'refDes',
      x: 0
      y: -settings.fontSize.name - 2
      halign: 'left'
      valign: 'bottom'
    .attribute 'name',
      x: 0
      y: -1
      halign: 'left'
      valign: 'bottom'

  leftX = -width/2
  rightX = width/2
  topY = -height/2
  bottomY = height/2

  rects = []

  if icon?
    rects.push
      x1: -icon.width/2
      y1: -icon.height/2
      x2: icon.width/2
      y2: icon.height/2

  # Pins on the top side
  dx = settings.fontSize.pin/2 + space
  y = topY
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

    h = pinTextWidth(symbol, pin, schematic.showPinNames) + space
    x1 = x - dx
    x2 = x + dx
    # Check whether pin rectangle intersects other rectangles
    for r in rects
      if intersects [x1, x2], [r.x1, r.x2]
        y1 = r.y1 - h - space
        if y > y1 then y = y1 # Make symbol higher
    x += step
    topRects.push
      x1: x1,
      y1: 0,
      x2: x2,
      y2: h

  topY = symbol.alignToGrid y, 'floor'

  for r in topRects
    r.y1 += topY
    r.y2 += topY
    rects.push r

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

    h = pinTextWidth(symbol, pin, schematic.showPinNames) + space
    x1 = x - dx
    x2 = x + dx
    # Check whether pin rectangle intersects other rectangles
    for r in rects
      if intersects [x1, x2], [r.x1, r.x2]
        y2 = r.y2 + h + space
        if y < y2 then y = y2 # Make symbol higher
    x += step
    bottomRects.push
      x1: x1,
      y1: -h,
      x2: x2,
      y2: 0

  bottomY = symbol.alignToGrid y, 'ceil'

  for r in bottomRects
    r.y1 += bottomY
    r.y2 += bottomY
    rects.push r

  # Pins on the left side
  x = leftX
  dy = settings.fontSize.pin/2 + space
  leftPins = []
  leftRects = []
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

    w = pinTextWidth(symbol, pin, schematic.showPinNames) + space
    y1 = y - dy
    y2 = y + dy
    # Check whether pin rectangle intersects other rectangles
    for r in rects
      if intersects [y1, y2], [r.y1, r.y2]
        x1 = r.x1 - w - space
        if x > x1 then x = x1 # Make symbol wider
    y += step
    leftRects.push
      x1: 0,
      y1: y1,
      x2: w,
      y2: y2

  leftX = symbol.alignToGrid x, 'floor'

  for r in leftRects
    r.x1 += leftX
    r.x2 += leftX
    rects.push r

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

    w = pinTextWidth(symbol, pin, schematic.showPinNames) + space
    y1 = y - dy
    y2 = y + dy
    # Check whether pin rectangle intersects other rectangles
    for r in rects
      if intersects [y1, y2], [r.y1, r.y2]
        x2 = r.x2 + w + space
        if x < x2 then x = x2 # Make symbol wider
    y += step

  rightX = symbol.alignToGrid x, 'ceil'

  # Update box size
  width = rightX - leftX
  height = bottomY - topY

  width = symbol.alignToGrid width, 'ceil'
  height = symbol.alignToGrid height, 'ceil'

  # Box
  symbol
    .lineWidth settings.lineWidth.thick
    .rectangle 0, 0, width, height, 'foreground'

  if icon? then symbol.icon -leftX, -topY, icon

  # Pins
  for pin in leftPins
    pin.x = -pinLength
    pin.y -= topY
    symbol.pin pin

  for pin in rightPins
    pin.x = width + pinLength
    pin.y -= topY
    symbol.pin pin

  for pin in topPins
    pin.x -= leftX
    pin.y = -pinLength
    symbol.pin pin

  for pin in bottomPins
    pin.x -= leftX
    pin.y = height + pinLength
    symbol.pin pin