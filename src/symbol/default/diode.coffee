Icons = require './common/icons'

module.exports = (symbol, element, styleIcons) ->
  element.refDes = 'D'
  schematic = element.schematic
  settings = symbol.settings

  pins = element.pins
  numbers = Object.keys pins
  decorated = numbers.length > 2

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= if decorated then true else true

  icon = if styleIcons? then new styleIcons.Diode(symbol, element) else new Icons.Diode(symbol, element)

  cathode = 1
  anode = 2
  nc = []
  for k, v of pins
    v.name = v.name.replace 'K', 'C'
    switch v.name
      when 'A'
        anode = v.number
      when 'C'
        cathode = v.number
      when 'NC'
        nc.push v.number
      else needEnclosure = true

  if needEnclosure
    schematic.showPinNames = true
    enclosure symbol, element, icon
  else
    width = icon.width
    height = icon.height

    pinLength = settings.pinLength ? (if decorated then 5 else 2.5)
    pinLength = (2*symbol.alignToGrid(width/2 + pinLength, 'ceil') - width) / 2

    symbol
      .attribute 'refDes',
        x: 0
        y: -height/2 - settings.space.attribute
        halign: 'center'
        valign: 'bottom'
      .attribute 'name',
        x: 0
        y: height/2 + settings.space.attribute
        halign: 'center'
        valign: 'top'
      .pin
        number: cathode
        name: 'C'
        x: width/2 + pinLength
        y: 0
        length: pinLength
        orientation: 'left'
        passive: true
      .pin
        number: anode
        name: 'A'
        x: -width/2 - pinLength
        y: 0
        length: pinLength
        orientation: 'right'
        passive: true

      pitch = symbol.alignToGrid 5
      for v, i in nc
        symbol
          .pin
            number: v
            name: 'NC'
            x: (i - (nc.length - 1)/2)*pitch
            y: height/2 + pinLength
            length: pinLength
            orientation: 'up'
            nc: true
            invisible: true

    icon.draw 0, 0

  [width, height]
