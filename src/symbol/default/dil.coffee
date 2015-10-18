module.exports = (symbol, pinCount) ->
  step = 2
  width = 20
  pinLen = 4

  height =  Math.round(step * pinCount/2)

  # Attributes
  symbol.addAttribute 'refDes',
    x: pinLen  + width/2
    y: - (step + 0.5)
    halign: 'center'
    valign: 'bottom'

  symbol.addAttribute 'name',
    x: pinLen + width/2
    y: height + 0.5
    halign: 'center'
    valign: 'top'

  # Rectangle
  symbol.addRectangle
    x: pinLen
    y: -step
    width: width
    height: height + step
    fill: 'foreground'

  # Pins on the left side
  y = 0
  for i in [1..pinCount/2]
    pin = symbol.element.pins[i]
    unless pin? then continue
    pin.x = 0
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
    pin.x = width + 2*pinLen
    pin.y = y
    pin.length = pinLen
    pin.orientation = 'left'
    symbol.addPin pin
    y -= step
