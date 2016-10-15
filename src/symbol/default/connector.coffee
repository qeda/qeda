enclosure = require './common/enclosure'
Icon = require './common/icon'

class PinIcon extends Icon
  constructor: (symbol, element) ->
    @width = 5
    @height = 5
    @pinShape = element.schematic.pinShape?.toLowerCase()
    super symbol, element

  draw: (x, y) ->
    r = @width/4
    if @pinShape is 'square'
      @symbol.poly x - r, y - r, x + r, y - r, x + r, y + r, x - r, y + r, x - r, y - r, 'background'
    else
      @symbol.circle x, y, r, 'background'

module.exports = (symbol, element) ->
  schematic = element.schematic

  element.refDes = 'J'
  pinIcon = new PinIcon(symbol, element)

  schematic.showPinNames ?= true
  schematic.showPinNumbers ?= true
  schematic.pinIcon = pinIcon
  schematic.symmetrical = true

  if (not symbol.left.length) and (not symbol.right.length) # Automatic
    numbers = Object.keys element.pins
    if schematic.single
      numbers.map (v) -> symbol.right.push v
    else if schematic.ccw
      half = Math.ceil numbers.length/2
      for i in [0..(half - 1)]
        symbol.left.push numbers[i]
      for i in [half..(numbers.length - 1)]
        symbol.right.unshift number
    else if schematic.cw
      half = Math.ceil numbers.length/2
      for i in [0..(half - 1)]
        symbol.right.push numbers[i]
      for i in [half..(numbers.length - 1)]
        symbol.left.unshift number
    else if schematic.mirror
      for number in numbers by 2
        symbol.right.push number
      numbers.shift()
      for number in numbers by 2
        symbol.left.push number
    else
      for number in numbers by 2
        symbol.left.push number
      numbers.shift()
      for number in numbers by 2
        symbol.right.push number

  pins = element.pins
  for k, v of pins
    pins[k].passive = true

  enclosure symbol, element
