module.exports = (symbol) ->
  step = 2
  width = 20
  pinLen = 4

  pinCount = 8 # TODO: Oops!
  height =  Math.round(step * pinCount/2)

  # Attributes
  symbol.addAttribute 'refDes',
    x: 0
    y: -height/2 - step/2 - 0.5
    halign: 'center'
    valign: 'bottom'

  symbol.addAttribute 'name',
    x: 0
    y: height/2 + step/2 + 0.5
    halign: 'center'
    valign: 'top'

  # Rectangle
  symbol.addRectangle
    x: -width/2
    y: -height/2 - step/2
    width: width
    height: height + step
    fill: 'foreground'

  # Pins on the left side
  y = -step * pinCount/4 + step/2
  for i in [1..pinCount/2]
    pin = symbol.element.pins[i]
    unless pin? then continue
    pin.x = -width/2 - pinLen
    pin.y = y
    pin.length = pinLen
    pin.orientation = 'right'
    symbol.addPin pin
    y += step

  # Pins on the right side
  y -= step
  for i in [(pinCount/2 + 1)..pinCount]
    pin = symbol.element.pins[i]
    unless pin? then continue
    pin.x = width/2 + pinLen
    pin.y = y
    pin.length = pinLen
    pin.orientation = 'left'
    symbol.addPin pin
    y -= step
