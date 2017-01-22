module.exports = (symbol, element, icon, left, right, nc) ->
  schematic = element.schematic
  settings = symbol.settings

  pins = element.pins
  numbers = Object.keys pins
  decorated = numbers.length > 2

  schematic.showPinNumbers ?= if decorated then true else false

  width = icon.width
  height = icon.height

  pinLength = settings.pinLength ? (if decorated then 5 else 2.5)
  pinLength = (2*symbol.alignToGrid(width/2 + pinLength, 'ceil') - width) / 2

  pitch = symbol.alignToGrid 5
  pinAreaHeight = (Math.max(left.length, right.length) - 1) * pitch

  symbol
    .attribute 'refDes',
      x: 0
      y: -height/2 - settings.space.attribute
      halign: 'center'
      valign: 'bottom'
    .attribute 'name',
      x: 0
      y: Math.max(height, pinAreaHeight)/2 + settings.space.attribute
      halign: 'center'
      valign: 'top'
  icon.draw 0, 0

  if left.length is 1
    symbol.pin
      number: left[0].number
      name: left[0].name
      x: -width/2 - pinLength
      y: 0
      length: pinLength
      orientation: 'right'
      passive: true
  else
    y = -pitch * (left.length - 1) / 2
    symbol
      .line -width/2 - pinLength, 0, -width/2, 0
      .line -width/2 - pinLength, y, -width/2 - pinLength, -y
    for pin in left
      pin.x = -width/2 - 2*pinLength
      pin.y = y
      pin.length = pinLength
      pin.orientation = 'right'
      pin.passive = true
      symbol.pin pin
      y += pitch

  if right.length is 1
    symbol.pin
      number: right[0].number
      name: right[0].name
      x: width/2 + pinLength
      y: 0
      length: pinLength
      orientation: 'left'
      passive: true
  else
    y = -pitch * (right.length - 1) / 2
    symbol
      .line width/2 , 0, width/2 + pinLength, 0
      .line width/2 + pinLength, y, width/2 + pinLength, -y
    for pin in right
      pin.x = width/2 + 2*pinLength
      pin.y = y
      pin.length = pinLength
      pin.orientation = 'left'
      pin.passive = true
      symbol.pin pin
      y += pitch

  if nc?
    for pin, i in nc
      pin.x = (i - (nc.length - 1)/2)*pitch
      pin.y = Math.max(height, pinAreaHeight)/2 + pinLength
      pin.length = pinLength
      pin.orientation = 'up'
      pin.nc = true
      pin.invisible = true
      symbol.pin pin
