Icon = require './icon'

#
# Amplifier
#
class AmplifierIcon extends Icon
  constructor: (symbol, element) ->
    super symbol, element, width=10, height=10
    @d =
      w: @width
      h: @height
      u: @height / 4
      s: @height / 16

  draw: (x, y) ->
    settings = @symbol.settings
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      .line -@d.w/2, -@d.h/2, @d.w/2, 0
      .line @d.w/2, 0, -@d.w/2, @d.h/2
      .line -@d.w/2, @d.h/2, -@d.w/2, -@d.h/2
      .line -@d.w/2 + @d.s, -@d.h/2 + @d.u, -@d.w/2 + @d.u - @d.s, -@d.h/2 + @d.u
      .line -@d.w/2 + @d.s, @d.h/2 - @d.u, -@d.w/2 + @d.u - @d.s, @d.h/2 - @d.u
      .line -@d.w/2 + @d.u/2, @d.h/2 - @d.u/2 - @d.s, -@d.w/2 + @d.u/2, @d.h/2 - @d.u/2*3 + @d.s

    @symbol.center 0, 0 # Restore default center point

#
# Capacitor
#
class CapacitorIcon extends Icon
  constructor: (symbol, element) ->
    super symbol, element, width=1.5, height=8
    @d =
      w: @width
      h: @height
      gap: @width/1.5
      r: 6*@width

  draw: (x, y) ->
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      # Left plate
      .line -@d.w/2, -@d.h/2, -@d.w/2, @d.h/2
    if @schematic.polarized
      # Right plate
      a = 180 * Math.asin(@d.h/(2*@d.r)) / Math.PI
      @symbol.arc @d.r + @d.w/2, 0, @d.r, 180 - a, 180 + a
      # Plus sign
      x = -@d.w/2 - 2*@d.gap
      y = -@d.h/4
      @symbol
        .lineWidth @settings.lineWidth.thin
        .line x - @d.gap, y, x + @d.gap, y
        .line x, y - @d.gap, x, y + @d.gap
        .lineWidth @lineWidth
    else
      # Right plate
      @symbol.line @d.w/2, -@d.h/2, @d.w/2, @d.h/2

    @symbol.center 0, 0 # Restore default center point

#
# Feedthrough Capacitor
#
class CapacitorFeedthroughIcon extends Icon
  constructor: (symbol, element) ->
    super symbol, element, width=8, height=3
    @d =
      w: @width
      h: @height

  draw: (x, y) ->
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      # Top plate
      .line -@d.w/2, @d.h/2, @d.w/2, @d.h/2
      # Bottom plate
      .line -@d.w/2, -@d.h/2, @d.w/2, -@d.h/2
      # Center plate
      .line -@d.w/2, 0, @d.w/2, 0
      .center 0, 0 # Restore default center point

#
# Coaxial Connector
#
class CoaxialConnectorIcon extends Icon
  constructor: (symbol, element) ->
    super symbol, element, width=8, height=8
    @d =
      w: @width
      h: @height
      r: @width / 2
      s: @width / 8

  draw: (x, y) ->
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      .arc 0, 0, @d.r, 160, if @schematic.switch then 20 else 0
      .arc 0, 0, @d.r, 200, if @schematic.switch then 340 else 360
      .circle 0, 0, @lineWidth, 'background'
    if @schematic.switch
      @symbol
        .line 4*@d.s, 0, 3*@d.s, 0
        .line 3*@d.s, 0, @d.s, -2*@d.s
        .line @d.s, -2*@d.s, -@d.s, -2*@d.s
        .line -4*@d.s, 0, -3*@d.s, 0
        .line -3*@d.s, 0, -@d.s, -2*@d.s+@lineWidth
        #.lineTo -@d.s, -2*@d.s
        #.line -@d.s, 0, 0, 0
        #.lineTo @d.s, -2*@d.s
    else
      @symbol.line -@d.r, 0, 0, 0
    @symbol.center 0, 0 # Restore default center point

#
# Crystal
#
class CrystalIcon extends Icon
  constructor: (symbol, element) ->
    super symbol, element, width=6, height=8
    @d =
      w: @width
      h: @height
      gap: @width/4
      dy: @height/4

  draw: (x, y) ->
    settings = @symbol.settings
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      # Body
      .rectangle -@d.w/2 + @d.gap, -@height/2, @d.w/2 - @d.gap, @height/2, settings.fill
      # Left plate
      .line -@d.w/2, -@d.h/2 + @d.dy, -@d.w/2, @d.h/2 - @d.dy
      # Right plate
      .line @d.w/2, -@d.h/2 + @d.dy, @d.w/2, @d.h/2 - @d.dy
      .center 0, 0 # Restore default center point

#
# Diode
#
class DiodeIcon extends Icon
  constructor: (symbol, element) ->
    super symbol, element, width=4, height=5
    if @schematic.tvs then @width *= 2
    @d =
      w: @width
      h: @height
      d: @width/4
      gap: Math.max(@height, @width)/4
      aw: @width/4
    if @schematic.tvs or @schematic.zener then @height += 2*@d.d

  draw: (x, y, rotated = false) ->
    settings = @symbol.settings
    f = if rotated then -1 else 1
    x1 = f * (-@d.w/2)
    y1 = f * (-@d.h/2)
    x2 = f * @d.w/2
    y2 = f * @d.h/2
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
    if @schematic.tvs
      d = f*@d.d
      @symbol
        # Left triangle
        .poly x1, y1, 0, 0, x1, y2, x1, y1, settings.fill
        # Right triangle
        .poly x2, y1, 0, 0, x2, y2, x2, y1, settings.fill
        # Central line
        .line 0, y1, 0, y2
        .line 0, y1, -d, y1 - d
        .line 0, y2, d, y2 + d
    else
      @symbol
        # Triangle & line
        .poly x1, y1, x2, 0, x1, y2, x1, y1, settings.fill
        .line x2, y1, x2, y2
      if @schematic.schottky
        d = f*@d.d
        @symbol
          # Bottom twirl
          .moveTo x2, y2
          .lineTo x2 - d, y2
          .lineTo x2 - d, y2 - d
          # Top twirl
          .moveTo x2, y1
          .lineTo x2 + d, y1
          .lineTo x2 + d, y1 + d
      else if @schematic.zener
        d = f*@d.d
        @symbol
          .line x2, y1, x2 - d, y1 - d
          .line x2, y2, x2 + d, y2 + d
      else if @schematic.led
        d = f*@d.gap
        len = 2*d

        xa = Math.max(@d.w, @d.h)/2
        ya = -xa
        x1 = xa
        y1 = ya - d
        x2 = xa + d
        y2 = ya
        # Arrows
        @symbol
          .line x1, y1, x1 + len, y1 - len
          .arrow x1 + len/2, y1 - len/2, x1 + len, y1 - len, @d.aw
          .line x2, y2, x2 + len, y2 - len
          .arrow x2 + len/2, y2 - len/2, x2 + len, y2 - len, @d.aw

    @symbol.center 0, 0 # Restore default center point

#
# FET
#
class FetIcon extends Icon
  constructor: (symbol, element) ->
    width = 15
    height = 9
    width = 2 * symbol.alignToGrid(width/2, 'ceil')
    height = 2 * symbol.alignToGrid(height/2, 'ceil')
    super symbol, element, width, height
    @d =
      w: @width
      h: @height
      space: @width/10
      gap: @height/9
      aw: @width/10

  draw: (x, y) ->
    dx = if @schematic.diode and (not @schematic.jfet) then -@d.w/8 else 0
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
    if @schematic.depletion or @schematic.jfet
      # Central line
      @symbol.line dx, -@d.h/2, dx, @d.h/2
    else # Enhancement
      # Three dashes
      y = -@d.h/2
      l = (@d.h - 2*@d.gap)/3
      for i in [1..3]
        @symbol.line dx, y, dx, y + l
        y += l + @d.gap

    y = (@d.h + @d.gap)/3
    @symbol
      .line dx, y, @d.w/2, y
      .line @d.w/2, y, @d.w/2, @d.h/2
      .line dx, -y, @d.w/2, -y
      .line @d.w/2, -y, @d.w/2, -@d.h/2

    if @schematic.jfet
      @symbol.line -@d.w/2, @d.h/2, dx, @d.h/2
      if @schematic.n then @symbol.arrow dx - @d.w/8, @d.h/2, dx, @d.h/2, @d.aw
      if @schematic.p then @symbol.arrow dx - @d.w/8, @d.h/2, dx - @d.w/4, @d.h/2, @d.aw
    else
      @symbol
        .line -@d.w/2, @d.h/2, dx - @d.space, @d.h/2
        .line dx - @d.space, -@d.h/2, dx - @d.space, @d.h/2
        .line dx, 0, dx + @d.w/4, 0
        .line dx + @d.w/4, 0, dx + @width/4, (@d.h + @d.gap)/3
      if @schematic.n then @symbol.arrow dx + @d.w/8, 0, dx, 0, @d.aw
      if @schematic.p then @symbol.arrow dx + @d.w/8, 0, dx + @d.w/4, 0, @d.aw

    if @schematic.diode
      x = @d.w/8 + @d.space
      w = @d.w/8
      h = w/2 * Math.tan(Math.PI/3)
      # Diode "pins"
      @symbol
        .line x + w/2, -(@d.h + @d.gap)/3, x + w/2, -h/2
        .line x + w/2, h/2, x + w/2, (@d.h + @d.gap)/3
      # Triangle and line
      if @schematic.n
        @symbol
          .polyline x, h/2, x + w, h/2, x + w/2, -h/2, x, h/2
          .line x, -h/2, x + w, -h/2
      else if @schematic.p
        @symbol
          .polyline x, -h/2, x + w, -h/2, x + w/2, h/2, x, -h/2
          .line x, h/2, x + w, h/2

    @symbol.center 0, 0 # Restore default center point

#
# Fuse
#
class FuseIcon extends Icon
  constructor: (symbol, element) ->
    super symbol, element, width=10, height=4
    @d =
      w: @width
      h: @height

  draw: (x, y) ->
    settings = @symbol.settings
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      .rectangle -@d.w/2, -@d.h/2, @d.w/2, @d.h/2, settings.fill
      .line -@d.w/2, 0, @d.w/2, 0

    @symbol.center 0, 0 # Restore default center point

#
# Inductor
#
class InductorIcon extends Icon
  constructor: (symbol, element) ->
    width = 20
    if element.schematic.ferrite
      super symbol, element, width=10, height=4
    else
      super symbol, element, width, height=width/8
    @d =
      w: @width
      h: @height
      r: @width/8
      lw: Math.sqrt(Math.pow(@width,2)/2)
      lh: Math.sqrt(Math.pow(@height,2)/2)
    if @schematic.ferrite
      @width = @d.lh * 2
      @height = @d.lw + @d.lh
    @y1 = -@height
    @y2 = 0

  draw: (x, y) ->
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)

    if @schematic.ferrite
      settings = @symbol.settings
      x = (@d.lw + @d.lh)/2
      y = x-@d.lw
      @symbol.poly x, y, y, x, -x, -y, -y, -x, settings.fill
    else
      x = -3*@d.r
      for i in [1..4]
        @symbol.arc x, 0, @d.r, 180, 0
        x += 2*@d.r

    @symbol.center 0, 0 # Restore default center point

#
# Pushbutton
#
class PushbuttonIcon extends Icon
  constructor: (symbol, element) ->
    super symbol, element, width=10, height=6
    @d =
      w: @width
      h: @height
      r: @height/6
    @y1 = -@height
    @y2 = @d.r
    @height += @d.r

  draw: (x, y) ->
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      .circle -@d.w/2 + @d.r, 0, @d.r
      .circle @d.w/2 - @d.r, 0, @d.r
      .line -@d.w/2, -@d.h/2, @d.w/2, -@d.h/2
      .line 0, -@d.h/2, 0, -@d.h
      .center 0, 0 # Restore default center point

#
# Resistor
#
class ResistorIcon extends Icon
  constructor: (symbol, element) ->
    super symbol, element, width=10, height=4
    @d =
      w: @width
      h: @height
      d: @height/4
    if @schematic.trimpot
      @height = 2*@height + @d.d
      @y1 = -@height/2 - @d.d
      @y2 = @height/2

  draw: (x, y) ->
    settings = @symbol.settings
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      .rectangle -@d.w/2, -@d.h/2, @d.w/2, @d.h/2, settings.fill
    if @schematic.trimpot
      @symbol
        .line -@d.h, @d.h,  @d.h, -@d.h
        .line @d.h - @d.d, -@d.h - @d.d,  @d.h + @d.d, -@d.h + @d.d
    @symbol.center 0, 0 # Restore default center point

#
# Switch
#
class SwitchIcon extends Icon
  constructor: (symbol, element) ->
    super symbol, element, width=4, height=8
    @d =
      w: @width
      h: @height

  draw: (x, y) ->
    settings = @symbol.settings
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      .rectangle -@d.w/2, -@d.h/2, @d.w/2, 0, 'none'
      .rectangle -@d.w/2, 0, @d.w/2, @d.h/2, 'background'
    @symbol.center 0, 0 # Restore default center point

#
# Transistor
#
class TransistorIcon extends Icon
  constructor: (symbol, element) ->
    width = 12
    height = 9
    width = 2 * symbol.alignToGrid(width/2, 'ceil')
    height = 2 * symbol.alignToGrid(height/2, 'ceil')
    super symbol, element, width, height
    @d =
      w: @width
      h: @height
      gap: @width/8
      aw: @width/8

  draw: (x, y) ->
    @symbol
      .lineWidth @lineWidth
      .center x, y # Set center to (x, y)
      .line 0, -@d.h/2, 0, @d.h/2
      .line 0, -@d.h/4, @d.w/2, -@d.h/2
      .line 0, @d.h/4, @d.w/2, @d.h/2
    if @schematic.igbt
      @symbol
        .line -@d.w/2, 0, -@d.gap, 0
        .line -@d.gap, -@d.h/2, -@d.gap, @height/2
    else
      @symbol
        .line -@d.w/2, 0, 0, 0

    dx = @d.w/2
    dy = @d.h/4
    x1 = dx/2
    y1 = @d.h/4 + dy/2
    x2 = x1 - dx/4
    y2 = y1 - dy/4
    a = Math.atan dy/dx
    if @schematic.npn or @schematic.igbt
      x3 = x2 + @d.aw*Math.sin(a)/2
      y3 = y2 - @d.aw*Math.cos(a)/2
      x4 = x2 - @d.aw*Math.sin(a)/2
      y4 = y2 + @d.aw*Math.cos(a)/2
      @symbol.poly x1, y1, x3, y3, x4, y4, 'background'
    if @schematic.pnp
      x3 = x1 + @d.aw*Math.sin(a)/2
      y3 = y1 - @d.aw*Math.cos(a)/2
      x4 = x1 - @d.aw*Math.sin(a)/2
      y4 = y1 + @d.aw*Math.cos(a)/2
      @symbol.poly x2, y2, x3, y3, x4, y4, 'background'

    @symbol.center 0, 0 # Restore default center point

#
# Export object
#
Icons = {}

Icons.Amplifier = AmplifierIcon
Icons.Capacitor = CapacitorIcon
Icons.CapacitorFeedthrough = CapacitorFeedthroughIcon
Icons.CoaxialConnector = CoaxialConnectorIcon
Icons.Crystal = CrystalIcon
Icons.Diode = DiodeIcon
Icons.Fet = FetIcon
Icons.Fuse = FuseIcon
Icons.Inductor = InductorIcon
Icons.Pushbutton = PushbuttonIcon
Icons.Resistor = ResistorIcon
Icons.Switch = SwitchIcon
Icons.Transistor = TransistorIcon

module.exports = Icons
