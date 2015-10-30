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
    y: 0
    halign: 'center'
    valign: 'bottom'

  symbol.addAttribute 'name',
    x: 0
    y: 0
    halign: 'center'
    valign: 'top'

  width = step * (Math.max(top.length, bottom.length) + 2)
  height = step * (Math.max(left.length, right.length) + 2)

  symbol.addRectangle
    x: -width/2
    y: -height/2
    width: width
    height: height
    fill: 'foreground'

  # Pins on the left side
  y = -step * left.length/2 + step/2
  for i in left
    if i is '-'
      y += step
      continue
    pin = pins[i]
    unless pin? then continue
    pin.x = -width/2 - pinLength
    pin.y = y
    pin.length = pinLength
    pin.orientation = 'right'
    symbol.addPin pin
    y += step

  # Pins on the right side
  y = -step * right.length/2 + step/2
  for i in right
    if i is '-'
      y += step
      continue
    pin = pins[i]
    unless pin? then continue
    pin.x = width/2 + pinLength
    pin.y = y
    pin.length = pinLength
    pin.orientation = 'left'
    symbol.addPin pin
    y += step

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

  #console.log width + ' x ' + height
  ###
  left = []
  right = []
  top = []
  bottom = []

  for groupName in part
    group = groups[groupName]
    if (schematic.left.indexOf(groupName) isnt -1) and (schematic.right.indexOf(groupName) isnt -1)
      len = group.length
      left = left.concat group[0..(len/2 - 1)]
      right = right.concat group[(len/2)..]
      left.push 0
      right.push 0
    else if schematic.left.indexOf(groupName) isnt -1
      left = left.concat group
      left.push 0
    else


    console.log groups[group]
  ###
  #console.log part
