intersects = (s1, s2) ->
  a1 = (s1[0] >= s2[0]) and (s1[0] <= s2[1])
  a2 = (s1[1] >= s2[0]) and (s1[1] <= s2[1])
  a3 = (s2[0] >= s1[0]) and (s2[0] <= s1[1])
  a4 = (s2[1] >= s1[0]) and (s2[1] <= s1[1])
  a1 or a2 or a3 or a4

module.exports = (symbol, element) ->
  element.refDes = 'U'
  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= true
  schematic.showPinNumbers ?= true

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
      y: -1
      halign: 'left'
      valign: 'bottom'
    .attribute 'name',
      x: 0
      y: -settings.fontSize.name - 2
      halign: 'left'
      valign: 'bottom'

  leftX = -width/2
  rightX = width/2
  topY = -height/2
  bottomY = height/2

  # Pins on the top side
  y = topY
  dx = settings.fontSize.pin/2 + space
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

    h = symbol.textWidth(pin.name, 'pin') + space
    x1 = x - dx
    x2 = x + dx
    if y > (-h - space) then y = -h - space
    x += step
    topRects.push
      x1: x1,
      y1: 0,
      x2: x2,
      y2: h

  topY = symbol.alignToGrid y, 'floor'

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

    h = symbol.textWidth(pin.name, 'pin') + space
    x1 = x - dx
    x2 = x + dx
    if y < (h + space) then y = h + space
    x += step
    bottomRects.push
      x1: x1,
      y1: -h,
      x2: x2,
      y2: 0

  bottomY = symbol.alignToGrid y, 'ceil'

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
  dy = settings.fontSize.pin/2 + space
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

    w = symbol.textWidth(pin.name, 'pin') + space
    y1 = y - dy
    y2 = y + dy
    # Check whether pin rectangle intersects other rectangles
    for r in rects
      if intersects [y1, y2], [r.y1, r.y2]
        x1 = r.x1 - w - space
        if x > x1 then x = x1 # Make symbol wider
    if x > -w then x = -w # Take text width in attention
    y += step

  leftX = symbol.alignToGrid x, 'floor'

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

    w = symbol.textWidth(pin.name, 'pin') + space
    y1 = y - dy
    y2 = y + dy
    # Check whether pin rectangle intersects other rectangles
    for r in rects
      if intersects [y1, y2], [r.y1, r.y2]
        x2 = r.x2 + w + space
        if x < x2 then x = x2 # Make symbol wider
    if x < w then x = w # Take text width in attention
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
