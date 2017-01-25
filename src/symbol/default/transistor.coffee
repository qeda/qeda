enclosure = require './common/enclosure'
Icons = require './common/icons'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'VT'
  schematic = element.schematic
  settings = symbol.settings
  pins = element.pins
  icon = new icons.Transistor(symbol, element)

  schematic.showPinNumbers = true

  groups = symbol.part ? element.pinGroups
  for k, v of groups
    k = k.toUpperCase()
    if (k.match /^B/) or (k.match /^G/) # `G` for IGBT
      base = v.map((e) => pins[e])
    else if k.match /^C/
      collector = v.map((e) => pins[e])
    else if k.match /^E/
      emitter = v.map((e) => pins[e])
    else if k is '' # Root group
      continue
    else
      needEnclosure = true

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
        x: width/2 - settings.fontSize.pin - settings.space.attribute
        y: -r - settings.space.attribute
        halign: 'right'
        valign: 'bottom'
      .attribute 'name',
        x: width/2 - settings.fontSize.pin - settings.space.attribute
        y: r + settings.space.attribute
        halign: 'right'
        valign: 'top'
      .lineWidth settings.lineWidth.thick
      .circle 0, 0, r, settings.fill
    icon.draw 0, 0

    # Base
    y = 0
    for pin in base
      pin.x = -width/2 - pinLength
      pin.y = y
      pin.length = pinLength
      pin.orientation = 'right'
      symbol.pin pin
      y += step
    symbol.line -width/2, 0, -width/2, (base.length - 1)*step

    # Collector
    x = width/2
    for pin in collector
      pin.x = x
      pin.y = -height/2 - pinLength
      pin.length = pinLength
      pin.orientation = 'down'
      symbol.pin pin
      x += step
    symbol.line width/2, -height/2, width/2 + (collector.length - 1)*step, -height/2

    # Emitter
    x = width/2
    for pin in emitter
      pin.x = x
      pin.y = height/2 + pinLength
      pin.length = pinLength
      pin.orientation = 'up'
      symbol.pin pin
      x += step
    symbol.line width/2, height/2, width/2 + (emitter.length - 1)*step, height/2
