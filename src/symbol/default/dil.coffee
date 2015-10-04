module.exports = (symbol, pinCount) ->
  symbol.refDes = 'U'
  leftPin =
    length: 2
    orientation: 'left'

  rightPin =
    length: 2
    orientation: 'right'

  step = 1

  for i in [1..pinCount/2]
    pinDef = symbol.pinDef i
    leftPin.x = 0
    leftPin.y = (i - 1) * step
    leftPin.name = pinDef.name
    symbol.addPin leftPin


  #for i in [pinCount/2..(pinCount-1)]
  #  element.setPos 10, i * step
  #  element.addPin rightPin

  #element.
