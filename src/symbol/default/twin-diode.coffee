Icons = require './common/icons'

module.exports = (symbol, element, styleIcons) ->
  element.refDes = 'D'
  schematic = element.schematic
  settings = symbol.settings
  pins = element.pins
  pinGroups = element.pinGroups

  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= true

  icon = if styleIcons? then new styleIcons.Diode(symbol, element) else new Icons.Diode(symbol, element)

  rotateLeft = false
  rotateRight = false
  names = Object.keys pinGroups
  for k, v of pins
    switch v.name
      when 'A' # A-|>-CA-|>-C or C-<|AC-<|-A or C1-<|-A-|>-C2
        if names.indexOf('C1') isnt -1
          rotateLeft = true
          middle = v
        else
          left = v
      when 'A1' then left = v # A1-|>-C-<|-A2
      when 'A2' then right = v # A1-|>-C-<|-A2
      when 'AC' then middle = v # C-<|AC-<|-A
      when 'C' # A-|>-CA-|>-C or C-<|AC-<|-A or A1-|>-C-<|-A2
        if names.indexOf('A1') isnt -1
          rotateRight = true
          middle = v
        else
          right = v
      when 'C1' then left = v # C1-<|-A-|>-C2
      when 'C2' then right = v # C1-<|-A-|>-C2
      when 'CA' then middle = v # A-|>-CA-|>-C
      else needEnclosure = true
  valid = left? and middle? and right?

  if (not valid) or needEnclosure
    schematic.showPinNames = true
    enclosure symbol, element, icon
  else
    space = icon.width/2
    width = 2*icon.width + 4*space
    width = 2*symbol.alignToGrid(width/2, 'ceil')
    height = icon.height + 2*space
    height = 2*symbol.alignToGrid(height/2, 'ceil')

    pinLength = settings.pinLength ? 5
    pinLength = symbol.alignToGrid(pinLength, 'ceil')

    symbol
      .attribute 'refDes',
        x: 0
        y: -height/2 - settings.space.attribute
        halign: 'center'
        valign: 'bottom'
      .attribute 'name',
        x: settings.space.attribute
        y: height/2 + settings.space.attribute
        halign: 'left'
        valign: 'top'
      .pin
        number: left.number
        name: left.name
        x: -width/2 - pinLength
        y: 0
        length: pinLength
        orientation: 'right'
        passive: true
      .pin
        number: middle.number
        name: middle.name
        x: 0
        y: height/2 + pinLength
        length: pinLength
        orientation: 'up'
        passive: true
      .pin
        number: right.number
        name: right.name
        x: width/2 + pinLength
        y: 0
        length: pinLength
        orientation: 'left'
        passive: true

    x1 = -width/4
    x2 = width/4
    icon.draw x1, 0, rotateLeft
    icon.draw x2, 0, rotateRight
    r = settings.lineWidth.thick
    symbol
      .rectangle -width/2, -height/2, width/2, height/2
      .line -width/2, 0, x1 - icon.width/2, 0
      .line x1 + icon.width/2, 0, x2 - icon.width/2, 0
      .line x2 + icon.width/2, 0, width/2, 0
      .line 0, 0, 0, height/2
      .circle 0, 0, r, 'background'
