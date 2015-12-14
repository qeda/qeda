designators =
  DA: ['analog']
  DD: ['digital']

purposes =
  RTX: ['isolator', 'interface', 'transceiver']
  PLM: ['CPLD']

updateElement = (element) ->
  unless element.keywords? then return
  keywords = element.keywords.replace(/\s+/g, '').split(',')
  refWeight = 0
  for designator, classes of designators
    weight = keywords.filter((a) => classes.indexOf(a) isnt -1).length
    if weight > refWeight
      refWeight = weight
      element.refDes = designator
  porposeWeight = 0
  for purpose, classes of purposes
    weight = keywords.filter((a) => classes.indexOf(a) isnt -1).length
    if weight > porposeWeight
      porposeWeight = weight
      element.purpose = purpose

module.exports = (symbol, element) ->
  element.refDes = 'D'
  element.purpose = ''
  updateElement element

  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= true
  schematic.showPinNumbers ?= true

  step = 2
  pinLength = settings.pinLenght ? 4

  left = symbol.left
  if symbol.top.length
    left.push '-'
    left = left.concat symbol.top
  right = symbol.right
  if symbol.bottom.length
    right.push '-'
    right = right.concat symbol.bottom

  pins = element.pins

  space = settings.space.pinName

  # Attributes
  symbol
    .attribute 'refDes',
      x: 0
      y: -0.5
      halign: 'center'
      valign: 'bottom'
    .attribute 'name',
      x: 0
      y: -settings.fontSize.refDes - 1
      halign: 'center'
      valign: 'bottom'
      visible: false
    .attribute 'user',
      x: 0
      y: 1.5
      halign: 'center'
      valign: 'top'
      text: element.purpose

  textWidth = element.purpose.length * settings.fontSize.name

  width = textWidth
  height = step * (Math.max(left.length, right.length) + 1)

  # Pins on the left side
  x = -width/2
  leftPins = []
  leftLines = []
  y = height/2 - step * left.length/2 + step/2
  for i in left
    if i is '-'
      leftLines.push y1: y, y2: y
      y += step
      continue
    pin = pins[i]
    unless pin? then continue
    pin.y = y
    pin.length = pinLength
    pin.orientation = 'right'
    leftPins.push pin

    w = pin.name.length*settings.fontSize.pinName + space
    x1 = -width/2 - w - space
    if x > x1 then x = x1 # Make symbol wider
    y += step

  width = Math.max width, -2*x

  # Pins on the right side
  x = width/2
  rightPins = []
  rightLines = []
  y = height/2 - step * right.length/2 + step/2
  for i in right
    if i is '-'
      rightLines.push y1: y, y2: y
      y += step
      continue
    pin = pins[i]
    unless pin? then continue
    pin.y = y
    pin.length = pinLength
    pin.orientation = 'left'
    rightPins.push pin

    w = pin.name.length*settings.fontSize.pinName + space
    x2 = textWidth/2 + w + space
    if x < x2 then x = x2 # Make symbol wider
    y += step

  width = Math.max width, 2*x
  width = Math.ceil(width/2) * 2 # Make width even

  # Box
  symbol
    .rectangle -width/2, 0, width/2, height, 'foreground'
    .line -textWidth/2 - space, 0, -textWidth/2 - space, height
    .line textWidth/2 + space, 0, textWidth/2 + space, height


  # Gap lines
  for line in leftLines
    symbol.line -width/2, line.y1, -textWidth/2 - space, line.y2

  for line in rightLines
    symbol.line width/2, line.y1, textWidth/2 + space, line.y2

  # Pins
  for pin in leftPins
    pin.x = -width/2 - pinLength
    symbol.pin pin

  for pin in rightPins
    pin.x = width/2 + pinLength
    symbol.pin pin
