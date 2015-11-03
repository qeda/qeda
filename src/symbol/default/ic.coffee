intersects = (s1, s2) ->
  a1 = (s1[0] >= s2[0]) and (s1[0] <= s2[1])
  a2 = (s1[1] >= s2[0]) and (s1[1] <= s2[1])
  a3 = (s2[0] >= s1[0]) and (s2[0] <= s1[1])
  a4 = (s2[1] >= s1[0]) and (s2[1] <= s1[1])
  a1 or a2 or a3 or a4

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

  width = step * (Math.max(top.length, bottom.length) + 2)
  height = step * (Math.max(left.length, right.length) + 2)
  space = settings.space.pinName

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

  textWidth = symbol.element.longestAlias.length * settings.fontSize.name
  textHeight = settings.fontSize.refDes + settings.fontSize.name + 1
  # Update box size
  width = Math.max width, textWidth + 2*space
  height = Math.max height, textHeight + 2*space

  rects = []
  rects.push
    x1:  -textWidth/2
    y1: -textHeight/2
    x2: textWidth/2
    y2: textHeight/2

  # Pins on the top side
  y = -height/2
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
    if y > -h - space then y = -h - space
    # Check whether pin rectangle intersects other rectangles
    for r in rects
      if intersects [x1, x2], [r.x1, r.x2]
        y1 = r.y1 - h - space
        if y > y1 then y = y1 # Make symbol larger
    x += step
    topRects.push
      x1: x1,
      y1: 0,
      x2: x2,
      y2: h

  topY = Math.floor y

  # Pins on the bottom side
  y = height/2
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
    if y < h + space then y = h + space
    # Check whether pin rectangle intersects other rectangles
    for r in rects
      if intersects [x1, x2], [r.x1, r.x2]
        y2 = r.y2 + h + space
        if y < y2 then y = y2 # Make symbol larger
    x += step
    bottomRects.push
      x1: x1,
      y1: -h,
      x2: x2,
      y2: 0

  bottomY = Math.ceil y

  for r in topRects
    r.y1 += topY
    r.y2 += topY
    rects.push r

  for r in bottomRects
    r.y1 += bottomY
    r.y2 += bottomY
    rects.push r

  # Pins on the left side
  x = -width/2
  dy = settings.fontSize.pinName/2 + space
  leftPins = []
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
    leftPins.push pin

    w = pin.name.length*settings.fontSize.pinName + space
    y1 = y - dy
    y2 = y + dy
    if x > -w - space then x = -w - space
    # Check whether pin rectangle intersects other rectangles
    for r in rects
      if intersects [y1, y2], [r.y1, r.y2]
        x1 = r.x1 - w - space
        if x > x1 then x = x1 # Make symbol wider
    y += step

  leftX = Math.floor x

  # Pins on the right side
  x = width/2
  rightPins = []
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
    rightPins.push pin

    w = pin.name.length*settings.fontSize.pinName + space
    y1 = y - dy
    y2 = y + dy
    if x < w + space then x = w + space
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
  y = 0
  if top.length > 0 then y = topY # Center aligned symbol
  symbol.addRectangle
    x: leftX
    y: y
    width: width
    height: height
    fill: 'foreground'

  for pin in leftPins
    pin.x = leftX - pinLength
    symbol.addPin pin

  for pin in rightPins
    pin.x = rightX + pinLength
    symbol.addPin pin

  for pin in topPins
    pin.y = topY - pinLength
    symbol.addPin pin

  for pin in bottomPins
    pin.y = bottomY + pinLength
    symbol.addPin pin
