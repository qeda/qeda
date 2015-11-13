designators =
  DA : ['analog']
  DD: ['digital']

purposes =
  RTX: ['isolator', 'interface', 'transceiver']
  PLD: ['CPLD']

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
  symbol.addAttribute 'refDes',
    x: 0
    y: -0.5
    halign: 'center'
    valign: 'bottom'

  symbol.addAttribute 'name',
    x: 0
    y: -settings.fontSize.refDes - 1
    halign: 'center'
    valign: 'bottom'
    visible: false

  symbol.addAttribute 'user',
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
  symbol.addRectangle
    x: -width/2
    y: 0
    width: width
    height: height
    fill: 'foreground'

  symbol.addLine
    x1: -textWidth/2 - space
    y1: 0
    x2: -textWidth/2 - space
    y2: height

  symbol.addLine
    x1: textWidth/2 + space
    y1: 0
    x2: textWidth/2 + space
    y2: height

  # Gap lines
  for line in leftLines
    line.x1 = -width/2
    line.x2 = -textWidth/2 - space
    symbol.addLine line

  for line in rightLines
    line.x1 = width/2
    line.x2 = textWidth/2 + space
    symbol.addLine line

  # Pins
  for pin in leftPins
    pin.x = -width/2 - pinLength
    symbol.addPin pin

  for pin in rightPins
    pin.x = width/2 + pinLength
    symbol.addPin pin
