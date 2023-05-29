enclosure = require './common/enclosure'
Icon = require './common/icon'

class DynodeIcon extends Icon
  constructor: (symbol, element) ->
    super symbol, element, width=5, height=5
    @d =
      r: @width / 2 * 0.8
      o: @width / 2
      l: @width / 4 * 0.8

  draw: (x, y) ->
    @symbol
      .arc x - @d.o, y, -@d.r, 90, 270
      .line x - @d.o, y, x + @d.o, y
      .line x - @d.o, y - @d.l, x - @d.o, y + @d.l

class AnodeIcon extends Icon
  constructor: (symbol, element, width) ->
    super symbol, element, width=width * 0.8, height=5
    @d =
      x: @width / 2
      y: @height / 2

  draw: (x, y) ->
    a = 180 * Math.asin(1) / Math.PI
    @symbol
      .line x - @d.x, y - @d.y, x + @d.x, y - @d.y
      .line x, y - @d.y, x, y + @d.y

class CathodeIcon extends Icon
  constructor: (symbol, element, width) ->
    super symbol, element, width=width * 0.8, height=5
    @d =
      y: @height / 2
      r: @width
      x: @width / 2

  draw: (x, y) ->
    a = 180 * Math.asin(@d.y/@d.x) / Math.PI
    @symbol
      .arc x, y + @d.r, @d.r, 90 - a, 90 + a
      .line x, y - @d.y, x, y

module.exports = (symbol, element) ->
  schematic = element.schematic
  settings = symbol.settings

  pitch = symbol.alignToGrid settings.pitch
  pinLength = symbol.alignToGrid(settings.pinLength ? 10)
  pinSpace = schematic.pinSpace ? settings.space.pin
  space = settings.space.default

  element.refDes = 'V'

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= true
  schematic.symmetrical = true
  anode = false
  cathode = false
  dynodes = []
  simpins = []
  for id in Object.keys element.pins
    pin = element.pins[id]
    if pin.name
      if pin.name.toUpperCase()[0] == 'P' || pin.name.toUpperCase()[0] == 'A'
        anode = id
      else if pin.name.toUpperCase()[0] == 'K' || pin.name.toUpperCase()[0] == 'C'
        cathode = id
      else if dynodenum = /\d+$/.exec pin.name
        dynodes[parseInt dynodenum[0]] = id
      else
        console.warn "Unknown pin '#{pin.name}' for photomultiplier"

  if schematic.simulation? == true
    simpins.push {name: 'SIM+', number: 'SIM+', passive: true}
    simpins.push {name: 'SIM-', number: 'SIM-', passive: true}

  pins = element.pins
  for k, v of pins
    pins[k].passive = true

  width = pitch * 4
  height = pitch * (Math.max(simpins.length, dynodes.length) + 3)
  
  dynIcon = new DynodeIcon(symbol, element)
  anIcon = new AnodeIcon(symbol, element, width)
  catIcon = new CathodeIcon(symbol, element, width)
  
  leftX = -width/2
  rightX = width/2
  topY = -height/2
  bottomY = height/2
  
  # Pins on the top side
  y = topY
  topPins = []
  x = 0
  pin = pins[cathode]
  pin.x = x
  pin.length = pinLength
  pin.orientation = 'down'
  topPins.push pin

  # Pins on the bottom side
  y = bottomY
  bottomPins = []
  x = 0
  pin = pins[anode]
  pin.x = x
  pin.length = pinLength
  pin.orientation = 'up'
  bottomPins.push pin

  # Pins on the left side
  leftPins = []
  y = -pitch*(Math.max(simpins.length, dynodes.length)/2 - 0.5)
  for pin in simpins
    unless pin? then continue
    pin.y = y
    y+= pitch
    pin.length = pinLength
    pin.orientation = 'right'
    leftPins.push pin

  # Pins on the right side
  rightPins = []
  y = -pitch*(Math.max(simpins.length, dynodes.length)/2 - 0.5)
  for i in dynodes
    pin = pins[i]
    unless pin? then continue
    pin.y = y
    y+= pitch
    pin.length = pinLength
    pin.orientation = 'left'
    rightPins.push pin

  # Box
  symbol
    .lineWidth settings.lineWidth.thick
    .rectangle 0, 0, width, height, settings.fill

  for pin in leftPins
    pin.x = -pinLength
    pin.y -= topY
    pin.space = pinSpace
    symbol.pin pin

  for pin in rightPins
    pin.x = width + pinLength
    pin.y -= topY
    pin.space = pinSpace
    symbol.pin pin
    dynIcon?.draw pin.x - pinLength - dynIcon.width/2, pin.y
    symbol.text
        x: pin.x - pinLength - dynIcon.width - pitch/10
        y: pin.y
        halign: 'right'
        valign: 'center'
        text: pin.name
        fontSize: settings.fontSize.pin

  for pin in topPins
    pin.x -= leftX
    pin.y = -pinLength
    pin.space = pinSpace
    symbol.pin pin
    catIcon?.draw pin.x, pin.y + pinLength + catIcon.height/2
    symbol.text
        x: pin.x
        y: pin.y + pinLength + catIcon.height/2 + pitch/10
        halign: 'center'
        valign: 'top'
        text: pin.name
        fontSize: settings.fontSize.pin

  for pin in bottomPins
    pin.x -= leftX
    pin.y = height + pinLength
    pin.space = pinSpace
    symbol.pin pin
    anIcon?.draw pin.x, pin.y - pinLength - anIcon.height/2
    symbol.text
        x: pin.x
        y: pin.y - pinLength - anIcon.height - pitch/10
        halign: 'center'
        valign: 'bottom'
        text: pin.name
        fontSize: settings.fontSize.pin

  # Attributes
  attributeSpace = settings.space.attribute
  symbol
    .attribute 'refDes',
      x: 0
      y: -attributeSpace
      halign: 'left'
      valign: 'bottom'

  symbol
    .attribute 'name',
      x: bottomPins[bottomPins.length - 1].x + attributeSpace
      y: height + attributeSpace
      halign: 'left'
      valign: 'top'