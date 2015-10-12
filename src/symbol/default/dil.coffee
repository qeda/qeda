module.exports = (symbol, pinCount) ->
  leftPin =
    length: 2
    orientation: 'left'

  rightPin =
    length: 2
    orientation: 'right'

  width = 6
  symbol.setAttribute 'refDes', x: width/2, y: 0, halign: 'center', valign: 'top'

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
