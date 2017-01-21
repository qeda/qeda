Icon = require './icon'

#
# Diode
#
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

        xa = Math.max(@width, @height)/2
        ya = -xa
        x1 = xa
        y1 = ya - d
        x2 = xa + d
        y2 = ya
        @symbol
          .line x1, y1, x1 + len, y1 - len
          .arrow x1 + len/2, y1 - len/2, x1 + len, y1 - len, arrowWidth
          .line x2, y2, x2 + len, y2 - len
          .arrow x2 + len/2, y2 - len/2, x2 + len, y2 - len, arrowWidth

    @symbol.center 0, 0 # Restore default center point

#
# FET
#
class FetIcon extends Icon
  constructor: (symbol, element) ->
    width = 15
    height = 9
    @width = 2 * symbol.alignToGrid(width/2, 'ceil')
    @height = 2 * symbol.alignToGrid(height/2, 'ceil')
    super symbol, element

  draw: (x, y) ->
    space = 1.5
    gap = 1
    arrowWidth = 1.5
    dx = if @schematic.diode and (not @schematic.jfet) then -@width/8 else 0
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
    if @schematic.depletion or @schematic.jfet
      @symbol.line dx, -@height/2, dx, @height/2
    else # Enhancement
      y = -@height/2
      l = (@height - 2*gap)/3
      for i in [1..3]
        @symbol.line dx, y, dx, y + l
        y += l + gap

    y = (@height + gap)/3
    @symbol
      .line dx, y, @width/2, y
      .line @width/2, y, @width/2, @height/2
      .line dx, -y, @width/2, -y
      .line @width/2, -y, @width/2, -@height/2

    if @schematic.jfet
      @symbol.line -@width/2, @height/2, dx, @height/2
      if @schematic.n then @symbol.poly dx - @width/8, @height/2 + arrowWidth/2, dx, @height/2, dx - @width/8, @height/2 - arrowWidth/2, 'background'
      if @schematic.p then @symbol.poly dx - @width/4, @height/2, dx - @width/8, @height/2 + arrowWidth/2, dx - @width/8, @height/2 - arrowWidth/2, 'background'
    else
      @symbol
        .line -@width/2, @height/2, dx - space, @height/2
        .line dx - space, -@height/2, dx - space, @height/2
        .line dx, 0, dx + @width/4, 0
        .line dx + @width/4, 0, dx + @width/4, (@height + gap)/3
      if @schematic.n then @symbol.poly dx, 0, dx + @width/8, arrowWidth/2, dx + @width/8, -arrowWidth/2, 'background'
      if @schematic.p then @symbol.poly dx + @width/8, arrowWidth/2, dx + @width/4, 0, dx + @width/8, -arrowWidth/2, 'background'

    if @schematic.diode
      x = @width/8 + space
      w = @width/8
      h = w/2 * Math.tan(Math.PI/3)
      @symbol
        .polyline x, -h/2, x + w, -h/2, x + w/2, h/2, x, -h/2
        .line x, h/2, x + w, h/2
        .line x + w/2, -(@height + gap)/3, x + w/2, -h/2
        .line x + w/2, h/2, x + w/2, (@height + gap)/3

    @symbol.center 0, 0 # Restore default center point

#
# Resistor
#
class ResistorIcon extends Icon
  constructor: (symbol, element) ->
    @width = 10
    @height = 4
    super symbol, element
    if @schematic.trimpot then @space = @height/2
  draw: (x, y) ->
    settings = @symbol.settings
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      .rectangle -@width/2, -@height/2, @width/2, @height/2, settings.fill
    if @schematic.trimpot
      d = 1
      @symbol
        .line -@height, @height,  @height, -@height
        .line @height - d, -@height - d,  @height + d, -@height + d
    @symbol.center 0, 0 # Restore default center point

#
# Export object
#
Icons = {}
Icons.Diode = DiodeIcon
Icons.FetIcon = FetIcon
Icons.Resistor = ResistorIcon
module.exports = Icons
