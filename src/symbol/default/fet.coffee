enclosure = require './common/enclosure'

icon = Object.create
  width: 12
  height: 9
  lineWidth: 0
  draw: (symbol, x, y) ->
    space = 1.5
    gap = 1
    symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      .line -space, -@height/2, -space, @height/2
    if @enhancement
      x = 0
      y = -@height/2
      l = (@height - 2*gap)/3
      for i in [1..3]
        symbol.line 0, y, 0, y + l
        y += l + gap
    else
      symbol.line 0, -@height/2, 0, @height/2

    y = (@height + gap)/3
    symbol
      .line -@width/2, 0, -space, 0
      .line 0, y, @width/2, y
      .line @width/2, y, @width/2, @height/2
      .line 0, -y, @width/2, -y
      .line @width/2, -y, @width/2, -@height/2

    if @bulk
      symbol
        .line 0, 0, @width/4, 0
        .line @width/4, 0, @width/4, y

    symbol.center 0, 0 # Restore default center point


module.exports = (symbol, element) ->
  element.refDes = 'VT'
  schematic = element.schematic
  settings = symbol.settings

  options = if schematic.options? then schematic.options.replace(/\s+/g, '').split(',') else []
  for option in options
    icon[option.toLowerCase()] = true
  icon.lineWidth = settings.lineWidth.thick

  if element.pins.length > 3 # With enclosure
    schematic.showPinNumbers = true
    schematic.showPinNames = true
    enclosure symbol, element, icon
  else # Simple symbol
    width = icon.width
    height = icon.weight
    pinLength = settings.pinLength ? 5
    symbol
      .attribute 'refDes',
        x: 0
        y: -height/2 - 1
        halign: 'center'
        valign: 'bottom'
      .attribute 'name',
        x: 0
        y: height/2 + 1
        halign: 'center'
        valign: 'bottom'
      .icon 0, 0, icon
    ###
      .pin
        number: 1
        name: 1
        x: -width/2 - pinLength
        y: height/2 - 1
        length: pinLength
        orientation: 'right'
        type: 'passive'
      .pin
        number: 2
        name: 2
        x: width/2 + pinLength
        y: height/2 - 1
        length: pinLength
        orientation: 'left'
        type: 'passive'
      ###
