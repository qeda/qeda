Icon = require './icon'

class DiodeIcon extends Icon
  constructor: (symbol, element) ->
    @width = 4
    @height = 5
    super symbol, element
    if @schematic.tvs then @width *= 2

  draw: (x, y, rotated = false) ->
    settings = @symbol.settings
    f = if rotated then -1 else 1
    x1 = f * (-@width/2)
    y1 = f * (-@height/2)
    x2 = f * @width/2
    y2 = f * @height/2
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
    if @schematic.tvs
      d = f*1
      @symbol
        .poly x1, y1, 0, 0, x1, y2, x1, y1, settings.fill
        .poly x2, y1, 0, 0, x2, y2, x2, y1, settings.fill
        .line 0, y1, 0, y2
        .line 0, y1, -d, y1 - d
        .line 0, y2, d, y2 + d
    else
      @symbol
        .poly x1, y1, x2, 0, x1, y2, x1, y1, settings.fill
        .line x2, y1, x2, y2
      if @schematic.schottky
        d = f*1
        @symbol
          .moveTo x2, y2
          .lineTo x2 - d, y2
          .lineTo x2 - d, y2 - d
          .moveTo x2, y1
          .lineTo x2 + d, y1
          .lineTo x2 + d, y1 + d
      else if @schematic.zener
        d = f*1
        @symbol
          .line x2, y1, x2 - d, y1 - d
          .line x2, y2, x2 + d, y2 + d
      else if @schematic.led
        space = 1
        d = f*1.5
        len = f*3
        arrowWidth = 1

        x = Math.max(@width, @height)/2
        y = -x
        x1 = x
        y1 = y - d
        x2 = x + d
        y2 = y
        @symbol
          .line x1, y1, x1 + len, y1 - len
          .arrow x1 + len/2, y1 - len/2, x1 + len, y1 - len, arrowWidth
          .line x2, y2, x2 + len, y2 - len
          .arrow x2 + len/2, y2 - len/2, x2 + len, y2 - len, arrowWidth

    @symbol.center 0, 0 # Restore default center point

Icons = {}
Icons.Diode = DiodeIcon
module.exports = Icons
