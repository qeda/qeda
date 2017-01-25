enclosure = require './common/enclosure'
Icons = require './common/icons'

module.exports = (symbol, element, icons = Icons) ->
  element.refDes = 'VT'
  schematic = element.schematic
  settings = symbol.settings
  pins = element.pins
  icon = new icons.Fet(symbol, element)

  schematic.showPinNumbers = true

  groups = symbol.part ? element.pinGroups
  for k, v of groups
    k = k.toUpperCase()
    if k.match /^G/
      gate = v.map((e) => pins[e])
    else if k.match /^D/
      drain = v.map((e) => pins[e])
    else if k.match /^S/
      source = v.map((e) => pins[e])
    else if k is '' # Root group
      continue
    else
      needEnclosure = true

  valid = gate? and drain? and source?

  if (not valid) or needEnclosure
    schematic.showPinNames = true
    enclosure symbol, element, icon
  else
    width = icon.width
    height = icon.height
    pinLength = symbol.alignToGrid(settings.pinLength ? 10)
    pitch = symbol.alignToGrid 5
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

    # Gate
    y = height/2
    for pin in gate
      pin.x = -width/2 - pinLength
      pin.y = y
      pin.length = pinLength
      pin.orientation = 'right'
      symbol.pin pin
      y += pitch
    symbol.line -width/2, 0, -width/2, (gate.length - 1)*pitch

    # Drain
    x = width/2
    for pin in drain
      pin.x = x
      pin.y = -height/2 - pinLength
      pin.length = pinLength
      pin.orientation = 'down'
      symbol.pin pin
      x += pitch
    symbol.line width/2, -height/2, width/2 + (drain.length - 1)*pitch, -height/2

    # Source
    x = width/2
    for pin in source
      pin.x = x
      pin.y = height/2 + pinLength
      pin.length = pinLength
      pin.orientation = 'up'
      symbol.pin pin
      x += pitch
    symbol.line width/2, height/2, width/2 + (source.length - 1)*pitch, height/2
