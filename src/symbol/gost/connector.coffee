compareFunction = (a, b) ->
  cap = /([A-Z]*)(\d+)/.exec a
  unless cap then return 0
  aLetter = cap[1]
  aNumber = cap[2]
  cap = /([A-Z]*)(\d+)/.exec b
  unless cap then return 0
  bLetter = cap[1]
  bNumber = cap[2]
  if aLetter != bLetter then return (aLetter - bLetter)
  aNumber - bNumber

module.exports = (symbol, element) ->
  element.refDes = 'X'

  schematic = element.schematic
  settings = symbol.settings

  schematic.showPinNames ?= true
  schematic.showPinNumbers ?= false

  pitch = settings.pitch ? 5
  pitch = 2*symbol.alignToGrid(pitch/2)
  pinLength = symbol.alignToGrid(settings.pinLength ? 5)
  pinSpace = schematic.pinSpace ? settings.space.pin
  space = settings.space.default

  pins = element.pins
  numbers = []
  if symbol.top.length
    numbers = numbers.concat symbol.top
  if symbol.left.length
    numbers = numbers.concat symbol.left
  if symbol.right.length
    numbers = numbers.concat symbol.right
  if symbol.bottom.length
    numbers = numbers.concat symbol.bottom
  if numbers.length is 0 then numbers = Object.keys pins
  numbers = numbers.filter((v) -> v isnt '--')
  numbers.sort compareFunction

  # Attributes
  symbol
    .attribute 'refDes',
      x: 0
      y: -settings.space.attribute
      halign: 'center'
      valign: 'bottom'

  height = pitch*(numbers.length + 1)

  firstText = 'Цепь'
  firstWidth = 35
  secondText = 'Конт.'
  secondWidth = 15

  y = 1.5 * pitch
  names = []
  rightPins = []
  for number in numbers
    pin = pins[number]
    pin.x = 0
    pin.y = y
    pin.length = pinLength
    pin.orientation = 'left'
    pin.passive = true
    w = symbol.textWidth(pin.name, 'pin') + 2*space
    if firstWidth < w then firstWidth = w
    names.push pin.name
    pin.name = number
    rightPins.push pin

    w = symbol.textWidth(pin.name, 'pin') + pinSpace
    if secondWidth < w + space then secondWidth = w + space
    y += pitch

  firstWidth = 2*symbol.alignToGrid(firstWidth/2, 'ceil')
  secondWidth = 2*symbol.alignToGrid(secondWidth/2, 'ceil')
  width = firstWidth + secondWidth

  if element.parts?
    symbol
      .attribute 'name',
        x: -width/2 - settings.space.attribute
        y: 0
        halign: 'right'
        valign: 'bottom'
        orientation: 'vertical'
  else
    symbol
      .attribute 'name',
        x: 0
        y: height + settings.space.attribute
        halign: 'center'
        valign: 'top'

  # Box
  symbol
    .lineWidth settings.lineWidth.thick
    .rectangle -width/2, 0, width/2, height, 'foreground'
    .line -width/2 + firstWidth, 0, -width/2 + firstWidth, height
    .text
      x: -width/2 + firstWidth/2
      y: pitch/2
      halign: 'center'
      valign: 'center'
      text: firstText
      fontSize: settings.fontSize.name
    .text
      x: width/2 - secondWidth/2
      y: pitch/2
      halign: 'center'
      valign: 'center'
      text: secondText
      fontSize: settings.fontSize.name

  # Pins
  y = pitch
  for pin, i in rightPins
    pin.x = width/2 + pinLength
    symbol
      .pin pin
      .line -width/2, y, width/2, y

    if names[i].length and schematic.showPinNames
      symbol.text
        x: -width/2 + firstWidth/2
        y: y + pitch/2
        halign: 'center'
        valign: 'center'
        text: names[i]
        fontSize: settings.fontSize.pin
    else
      symbol.attribute 'Net' + pin.number,
        text: 'NET'+ pin.number
        x: -width/2 + firstWidth/2
        y: y + pitch/2
        halign: 'center'
        valign: 'center'

    y += pitch

  schematic.showPinNames = true
