enclosure = require './common/enclosure'
Icon = require './common/icon'

class TransistorIcon extends Icon
  constructor: (symbol, element) ->
    width = 12
    height = 9
    @width = 2 * symbol.alignToGrid(width/2, 'ceil')
    @height = 2 * symbol.alignToGrid(height/2, 'ceil')
    super symbol, element

  draw: (x, y) ->
    arrowWidth = 1.5
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      .line -@width/2, 0, 0, 0
      .line 0, -@height/2, 0, @height/2
      .line 0, -@height/4, @width/2, -@height/2
      .line 0, @height/4, @width/2, @height/2

    dx = @width/2
    dy = @height/4
    x1 = dx/2
    y1 = @height/4 + dy/2
    x2 = x1 - dx/4
    y2 = y1 - dy/4
    a = Math.atan dy/dx
    if @schematic.npn
      x3 = x2 + arrowWidth*Math.sin(a)/2
      y3 = y2 - arrowWidth*Math.cos(a)/2
      x4 = x2 - arrowWidth*Math.sin(a)/2
      y4 = y2 + arrowWidth*Math.cos(a)/2
      @symbol.poly x1, y1, x3, y3, x4, y4, 'background'
    if @schematic.pnp
      x3 = x1 + arrowWidth*Math.sin(a)/2
      y3 = y1 - arrowWidth*Math.cos(a)/2
      x4 = x1 - arrowWidth*Math.sin(a)/2
      y4 = y1 + arrowWidth*Math.cos(a)/2
      @symbol.poly x2, y2, x3, y3, x4, y4, 'background'

    @symbol.center 0, 0 # Restore default center point

module.exports = (symbol, element) ->
  element.refDes = 'VT'
  schematic = element.schematic
  settings = symbol.settings
  pins = element.pins
  pinGroups = element.pinGroups

  schematic.showPinNumbers = true

  icon = new TransistorIcon(symbol, element)

  for k, v of pinGroups
    switch k
      when 'B' then base = v
      when 'C' then collector = v
      when 'E' then emitter = v
      else needEnclosure = true
  valid = base? and collector? and emitter?

  if (not valid) or needEnclosure
    schematic.showPinNames = true
    enclosure symbol, element, icon
  else
    width = icon.width
    height = icon.height
    pinLength = symbol.alignToGrid(settings.pinLength ? 10)
    step = symbol.alignToGrid 5
    r = width/2
    symbol
      .attribute 'refDes',
        x: 0
        y: -r - 1
        halign: 'right'
        valign: 'bottom'
      .attribute 'name',
        x: r + 1
        y: 0
        halign: 'left'
        valign: 'center'
      .lineWidth settings.lineWidth.thick
      .circle 0, 0, r
    icon.draw 0, 0

    # Base
    y = 0
    for b in base
      pin = pins[b]
      pin.x = -width/2 - pinLength
      pin.y = y
      pin.length = pinLength
      pin.orientation = 'right'
      symbol.pin pin
      y += step
    symbol.line -width/2, 0, -width/2, (base.length - 1)*step

    # Collector
    x = width/2
    for c in collector
      pin = pins[c]
      pin.x = x
      pin.y = -height/2 - pinLength
      pin.length = pinLength
      pin.orientation = 'down'
      symbol.pin pin
      x += step
    symbol.line width/2, -height/2, width/2 + (collector.length - 1)*step, -height/2

    # Emitter
    x = width/2
    for e in emitter
      pin = pins[e]
      pin.x = x
      pin.y = height/2 + pinLength
      pin.length = pinLength
      pin.orientation = 'up'
      symbol.pin pin
      x += step
    symbol.line width/2, height/2, width/2 + (emitter.length - 1)*step, height/2
