Icon = require '../../default/common/icon'

class DiodeIcon extends Icon
  constructor: (symbol, element) ->
    @width = 4
    @height = 5
    super symbol, element

  draw: (x, y, rotated = false) ->
    f = if rotated then -1 else 1
    d = f * 1.5
    x1 = f * (-@width/2)
    y1 = f * (-@height/2)
    x2 = f * @width/2
    y2 = f * @height/2
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      .polyline x1, y1, x2, 0, x1, y2, x1, y1
      .line x1, 0, x2, 0
      .line x2, y1, x2, y2
    if @schematic.schottky
      @symbol
        .moveTo x2, y2
        .lineTo x2 - d, y2
        .moveTo x2, y1
        .lineTo x2 + d, y1
    else if @schematic.zener
      @symbol
        .moveTo x2, y2
        .lineTo x2 - d, y2

    @symbol.center 0, 0 # Restore default center point

Icons = {}
Icons.Diode = DiodeIcon
module.exports = Icons
