module.exports = (symbol, pinCount) ->
  step = 2
  width = 20
  pinLen = 4

  height =  Math.round(step * pinCount/2)

  # Attributes
  symbol.addAttribute 'refDes',
    x: pinLen  + width/2
    y: - (step + 1)
    halign: 'center'
    valign: 'bottom'

  symbol.addAttribute 'name',
    x: pinLen + width/2
    y: height + 1
    halign: 'center'
    valign: 'top'

  # Pins on left side
  y = 0
  for i in [1..pinCount/2]
    pin = symbol.pin i
    pin.x = 0
    pin.y = y
    pin.length = pinLen
    pin.orientation = 'right'
    symbol.addPin pin
    y += step

  # Pins on right side
  y -= step
  for i in [(pinCount/2 + 1)..pinCount]
    pin = symbol.pin i
    pin.x = width + 2*pinLen
    pin.y = y
    pin.length = pinLen
    pin.orientation = 'left'
    symbol.addPin pin
    y -= step

  # Rectangle
  symbol.addRectangle
    x: pinLen
    y: -step
    width: width
    height: height + step
    filled: 'foreground'
