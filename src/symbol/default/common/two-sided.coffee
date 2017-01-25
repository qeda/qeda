module.exports = (symbol, element, icon, left, right, nc) ->
  schematic = element.schematic
  settings = symbol.settings

  decorated = (left.length > 1) or (right.length > 1) or (nc?.length)

  schematic.showPinNumbers ?= if decorated then true else false

  width = icon.width
  height = icon.height

  pinLength2 = symbol.alignToGrid(settings.pinLength ? (if decorated then 5 else 2.5), 'ceil')
  pinLength1 = (2*symbol.alignToGrid(width/2 + pinLength2, 'ceil') - width) / 2

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
      x: -width/2 - pinLength1
      y: 0
      length: pinLength1
      orientation: 'right'
      passive: true
  else
    y = -pitch * (left.length - 1) / 2
    symbol
      .line -width/2 - pinLength1, 0, -width/2, 0
      .line -width/2 - pinLength1, y, -width/2 - pinLength1, -y
    for pin in left
      pin.x = -width/2 - pinLength1 - pinLength2
      pin.y = y
      pin.length = pinLength2
      pin.orientation = 'right'
      pin.passive = true
      symbol.pin pin
      y += pitch

  if right.length is 1
    symbol.pin
      number: right[0].number
      name: right[0].name
      x: width/2 + pinLength1
      y: 0
      length: pinLength1
      orientation: 'left'
      passive: true
  else
    y = -pitch * (right.length - 1) / 2
    symbol
      .line width/2 , 0, width/2 + pinLength1, 0
      .line width/2 + pinLength2, y, width/2 + pinLength1, -y
    for pin in right
      pin.x = width/2 + pinLength1 + pinLength2
      pin.y = y
      pin.length = pinLength2
      pin.orientation = 'left'
      pin.passive = true
      symbol.pin pin
      y += pitch

  if nc?
    for pin, i in nc
      pin.x = (i - (nc.length - 1)/2)*pitch
      pin.y = Math.max(height, pinAreaHeight)/2 + pinLength2
      pin.length = pinLength2
      pin.orientation = 'up'
      pin.nc = true
      pin.invisible = true
      symbol.pin pin
