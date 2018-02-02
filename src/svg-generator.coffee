fs = require 'fs'
mkdirp = require 'mkdirp'
sprintf = require('sprintf-js').sprintf

log = require './qeda-log'

svg_head = """
<svg xmlns="http://www.w3.org/2000/svg"
     xmlns:xlink="http://www.w3.org/1999/xlink"
     xmlns:s="https://github.com/nturley/netlistsvg">

"""

svg_tail = """
</svg>

"""

netlistsvg_properties = """
<s:properties
  constants="false"
  splitsAndJoins="false"
  genericsLaterals="true">
  <s:layoutEngine
    org.eclipse.elk.layered.spacing.nodeNodeBetweenLayers="5"
    elk.spacing.nodeNode= "35"
    org.eclipse.elk.direction="DOWN"/>
  <s:low_priority_alias val="$dff" />
</s:properties>
"""

netlistsvg_style = """
<style>
svg {
  stroke: #000;
  fill: none;
  stroke-linejoin: round;
  stroke-linecap: round;
}
text {
  fill: #000;
  stroke: none;
  font-family: "Courier New", monospace;
}
</style>

"""

pcbsvg_style = """
<style>
svg {
  stroke: #000;
  fill: none;
}
text {
  fill: #000;
  stroke: none;
  font-family: "Courier New", monospace;
}
.topCopper {
  fill: red;
}
.bottomCopper {
  fill: green;
}
.topSilkscreen, .bottomSilkscreen {
  stroke: yellow;
  stroke-linejoin: round;
  stroke-linecap: round;
}
.topCourtyard, .bottomCourtyard {
  stroke: blue;
  stroke-linejoin: round;
  stroke-linecap: round;
}
.topAssembly, .bottomAssembly {
  stroke: purple;
  stroke-linejoin: round;
  stroke-linecap: round;
}
</style>

"""

netlistsvg_builtins = """
<!-- builtin -->
<g s:type="generic" s:width="30" s:height="40" transform="translate(40,20)">
  <s:alias val="ic"/>
  <text x="15" y="-4" s:attribute="ref" text-anchor="middle" font-size="10">generic</text>
  <rect width="30" height="40" x="0" y="0" s:generic="body"/>
  <g transform="translate(30,10)"
     s:x="30" s:y="10" s:pid="out0" s:position="left">
    <text x="5" y="-4" font-size="10" text-anchor="start">out0</text>
  </g>
  <g transform="translate(30,30)"
     s:x="30" s:y="30" s:pid="out1" s:position="left">
    <text x="5" y="-4" font-size="10" text-anchor="start">out1</text>
  </g>
  <g transform="translate(0,10)"
     s:x="0" s:y="10" s:pid="in0" s:position="right">
      <text x="-3" y="-4" font-size="10" text-anchor="end">in0</text>
  </g>
  <g transform="translate(0,30)"
     s:x="0" s:y="30" s:pid="in1" s:position="right">
    <text x="-3" y="-4" font-size="10" text-anchor="end">in1</text>
  </g>
</g>
<!-- builtin -->

"""

polarToCartesian = (centerX, centerY, radius, angleInDegrees) ->
  angleInRadians = (angleInDegrees-90) * Math.PI / 180.0

  return {
    x: centerX + (radius * Math.cos(angleInRadians)),
    y: centerY + (radius * Math.sin(angleInRadians))
  }

describeArc = (shape) ->
  start = polarToCartesian(shape.x, shape.y, shape.radius, shape.end + 90)
  end = polarToCartesian(shape.x, shape.y, shape.radius, shape.start + 90)

  largeArcFlag = if shape.end - shape.start <= 180 then "0" else "1"

  m = "M#{start.x},#{start.y}"
  a ="A#{shape.radius},#{shape.radius} 0 #{largeArcFlag} 0 #{end.x},#{end.y}"

  return "#{m} #{a}"

describePoly = (shape) ->
  d = []
  for [x, y] from iterPoints(shape)
    cmd = if d.length == 0 then 'M' else 'L'
    d.push("#{cmd}#{x},#{y}")
  return d.join(' ')

boundingBox = (iterator) ->
  minx = maxx = miny = maxy = 0
  for [x, y] from iterator()
    minx = Math.min(minx, x)
    maxx = Math.max(maxx, x)
    miny = Math.min(miny, y)
    maxy = Math.max(maxy, y)
  return [minx, miny, maxx, maxy]

iterPoints = (shape) ->
  switch shape.kind
    when 'pin'
      yield [shape.x, shape.y]
    when 'pad'
      yield [
        shape.x + shape.width/2,
        shape.y + shape.height/2
      ]
      yield [
        shape.x - shape.width/2,
        shape.y - shape.height/2
      ]
    when 'attribute'
      yield [shape.x, shape.y + shape.fontSize]
      yield [shape.x, shape.y - shape.fontSize]
    when 'line', 'rectangle'
      yield [shape.x1, shape.y1]
      yield [shape.x2, shape.y2]
    when 'circle', 'arc'
      yield [shape.x - shape.radius, shape.y - shape.radius]
      yield [shape.x + shape.radius, shape.y + shape.radius]
    when 'poly'
      for i from [0..(shape.points.length-1)]
        if i % 2 == 0
          yield [shape.points[i], shape.points[i+1]]

translate = (shift_x, shift_y) ->
  return (coord) -> [coord[0] + shift_x, coord[1] + shift_y]

rotateShape = (shape, angle, transformer) ->
  rotator = {
    90: (c) -> [-c[1], c[0]],
    180: (c) -> [-c[0], -c[1]],
    270: (c) -> [c[1], -c[0]],
  }
  rotate = rotator[angle]

  switch shape.kind
    when 'pin'
      [shape.x, shape.y] = transformer([shape.x, shape.y], rotate)
      [shape.xdir, shape.ydir] = rotate([shape.xdir, shape.ydir])
      if shape.xdir == 0
        if shape.ydir == 1
          shape.orientation = 'down'
          shape.position = 'top'
        else
          shape.orientation = 'up'
          shape.position = 'bottom'
      else
        if shape.xdir == 1
          shape.orientation = 'left'
          shape.position = 'right'
        else
          shape.orientation = 'right'
          shape.position = 'left'
    when 'line'
      [shape.x1, shape.y1] = transformer([shape.x1, shape.y1], rotate)
      [shape.x2, shape.y2] = transformer([shape.x2, shape.y2], rotate)
    when 'circle'
      [shape.x, shape.y] = transformer([shape.x, shape.y], rotate)
    when 'attribute'
      [shape.x, shape.y] = transformer([shape.x, shape.y], rotate)
      [shape.dx, shape.dy] = rotate([shape.dx, shape.dy])
      if angle == '90' or angle == '270'
        shape.writing_mode = 'tb'
      if angle == '180' or angle == '270'
        if shape.anchor == 'start'
          shape.anchor = 'end'
        else if shape.anchor == 'end'
          shape.anchor = 'start'
    when 'rectangle'
      dx = dxp = (shape.x2 - shape.x1) / 2
      dy = dyp = (shape.y2 - shape.y1) / 2

      if angle == '90' or angle == '270'
        [dxp, dyp] = [dyp, dxp]

      transform = (c) -> translate(-dxp, -dyp)(rotate(translate(dx, dy)(c)))
      [shape.x1, shape.y1] = transformer([shape.x1, shape.y1], transform)
      [shape.x2, shape.y2] = transformer([shape.x2, shape.y2], transform)
    when 'arc'
      [shape.x, shape.y] = transformer([shape.x, shape.y], rotate)
      shape.start += Number(angle)
      shape.end += Number(angle)
    when 'poly'
      for i from [0..(shape.points.length-1)]
        if i % 2 == 0
          [shape.points[i], shape.points[i+1]] =
            transformer([shape.points[i], shape.points[i+1]], rotate)

rotateSymbol = (symbol, angle) ->
  if typeof angle != 'string'
    angle = String(angle)

  if angle == '0'
    return

  cx = cxp = symbol.width / 2
  cy = cyp = symbol.height / 2

  if angle == '90' or angle == '270'
    [cxp, cyp] = [cyp, cxp]
    [symbol.width, symbol.height] = [symbol.height, symbol.width]

  transformer = (c, transform) -> translate(cxp, cyp)(transform(translate(-cx, -cy)(c)))

  symbol.shapes.forEach((shape) ->
    rotateShape(shape, angle, transformer))


#
# Generator of library in SVG format
#
class SvgGenerator
  #
  # Constructor
  #
  constructor: (@library) ->
    @dir = './svg'
    @f = "%.#{@library.pattern.decimals}f"
    @x_pos = 120
    @y_pos = 20
    @max_height = 40
    @spacing = 20

  #
  # Generate symbol library and footprint files
  #
  generate: (@name) ->
    symbols = []
    symbol_lookup = {}
    patterns = {}
    for element in @library.elements
      symbol = element.schematic.symbol
      options = element.schematic.options

      string = "#{symbol} #{if options? then options else ''}"
      name = (string.match(/[^\s,]+/g) or []).join('-').toLowerCase()

      showPinNames = if element.schematic?.showPinNames then true else false
      showPinNumbers = if element.schematic?.showPinNumbers then true else false

      if name.startsWith('connector') or name.startsWith('ic')
        # Use generic component
        continue

      aliases = [element.name].concat(element.aliases)
      if not (showPinNames or showPinNumbers)
        aliases = [name].concat(aliases)

      if not (aliases[0] of symbol_lookup)
        symbol_lookup[aliases[0]] = symbols.length
        symbols.push({
          'name': name,
          'aliases': aliases,
          # doesn't handle multipart symbols yet
          'symbol': element.symbols[0],
          'showPinNames': showPinNames,
          'showPinNumbers': showPinNumbers,
        })
      else
        sym = symbols[symbol_lookup[aliases[0]]]
        sym.aliases = sym.aliases.concat(aliases)

      if element.pattern? then patterns[element.pattern.name] = element.pattern

    # Symbols
    log.start "SVG symbols skin '#{@name}.svg'"
    mkdirp.sync "#{@dir}"
    fd = fs.openSync "#{@dir}/#{@name}.svg", 'w'
    fs.writeSync fd, svg_head
    fs.writeSync fd, netlistsvg_properties
    fs.writeSync fd, netlistsvg_style
    fs.writeSync fd, netlistsvg_builtins

    for symbol in symbols
      for orientation in symbol.symbol.orientations
        @_generateSymbol fd, symbol.name, symbol.aliases, symbol.symbol,
                         orientation, symbol.showPinNames, symbol.showPinNumbers

    fs.writeSync fd, svg_tail
    fs.closeSync fd
    log.ok()

    # Footprints
    for patternName, pattern of patterns
      log.start "SVG footprint '#{patternName}.svg'"
      mkdirp.sync "#{@dir}/#{@name}"
      fd = fs.openSync "#{@dir}/#{@name}/#{patternName}.svg", 'w'
      fs.writeSync fd, svg_head
      fs.writeSync fd, pcbsvg_style
      @_generatePattern fd, pattern
      fs.writeSync fd, svg_tail
      fs.closeSync fd
      log.ok()

  #
  # Write symbol entry to svg file
  #
  _generateSymbol: (fd, name, aliases, symbol, orientation,
                    showPinNames, showPinNumbers) ->
    clone = JSON.parse(JSON.stringify(symbol))

    # Preprocess symbol
    for shape in clone.shapes
      @_preprocessShape(shape, @library.symbol, false)
    # Bounding box
    [minx, miny, width, height] = @_getBoundingBox(clone)

    # Scale and shift and rotate symbol
    clone.width = width
    clone.height = height
    symbol.resize.call(clone, 10, true, -minx, -miny)
    rotateSymbol(clone, orientation)

    orientation_postfix = if orientation == 0 then '' else '_rot' + orientation

    # Symbol start
    fs.writeSync fd, """
    <g s:type="#{name}#{orientation_postfix}"
       s:width="#{clone.width}"
       s:height="#{clone.height}"
       transform="translate(#{@x_pos}, #{@y_pos})">

    """

    # Update skin position for next symbol
    @x_pos += clone.width + @spacing
    @max_height = Math.max(@max_height, clone.height)
    if @x_pos >= 1200
      @x_pos = @spacing
      @y_pos += @max_height + @spacing
      @max_height = 0

    # Write aliases
    aliases.forEach((alias) =>
      string = """
      <s:alias val="#{alias}#{orientation_postfix}"/>

      """
      fs.writeSync fd, string)

    # Write shapes
    clone.shapes.forEach((shape) =>
      fs.writeSync fd, @_shapeToSvg shape, showPinNames, showPinNumbers)

    # Symbol end
    fs.writeSync fd, """
    </g>

    """

  #
  # Write pattern to svg file
  #
  _generatePattern: (fd, pattern) ->
    # Preprocess pattern
    for shape in pattern.shapes
      @_preprocessShape(shape, @library.pattern, true)
    # Bounding box
    [minx, miny, width, height] = @_getBoundingBox(pattern)

    # Pattern start
    fs.writeSync fd, """
    <g transform="translate(10, 10) scale(100, 100) translate(#{width/2}, #{height/2})">

    """

    # Write shapes
    pattern.shapes.forEach((shape) =>
      fs.writeSync fd, @_shapeToSvg shape)

    # Pattern end
    fs.writeSync fd, """</g>

    """

  #
  # Returns an SVG representation of a shape
  #
  _shapeToSvg: (shape, showPinNames, showPinNumbers) ->
    if shape.visible == false
      return ""

    switch shape.kind
      when 'pin'
        pin_text = ''
        writing_mode = 'lr'
        text_anchor = 'start'
        if showPinNames
          pin_text = shape.name
          if shape.position in ['top', 'bottom']
            writing_mode = 'tb'
            dx = 0.4
          if shape.position in ['right', 'bottom']
            text_anchor = 'end'
        else if showPinNumbers
          pin_text = shape.number

        dx = 0
        dy = 0
        if shape.position in ['left', 'right']
          dy = -0.4
        else
          dx = 0.6

        return """
        <g s:x="#{shape.x}"
           s:y="#{shape.y}"
           s:pid="#{shape.name}"
           s:position="#{shape.position}">
          <line x1="#{shape.x}"
                y1="#{shape.y}"
                x2="#{shape.x + shape.xdir * shape.length}"
                y2="#{shape.y + shape.ydir * shape.length}"
                stroke-width="#{shape.lineWidth}"/>
          <text x="#{shape.x}"
                y="#{shape.y}"
                writing-mode="#{writing_mode}"
                text-anchor="#{text_anchor}"
                font-size="#{shape.fontSize}"
                dx="#{dx}em"
                dy="#{dy}em">#{pin_text}</text>
        </g>

        """
      when 'pad'
        attributes = """
        s:x="#{shape.x}" s:y="#{shape.y}" s:pid="#{shape.name}"
        class="#{shape.layer}"
        """

        switch shape.shape
          when 'rectangle'
            return """
              <rect x="#{shape.x - shape.width/2}" y="#{shape.y - shape.height/2}"
                    width="#{shape.width}" height="#{shape.height}"
                    stroke-width="0"
                    #{attributes}/>

            """
          when 'circle'
            return """
            <ellipse cx="#{shape.x}" cy="#{shape.y}"
                     rx="#{shape.width/2}" ry="#{shape.height/2}"
                     stroke-width="#{shape.lineWidth}"
                     #{attributes}/>
            """
      when 'attribute'
        return """
        <text x="#{shape.x}" y="#{shape.y}" font-size="#{shape.fontSize}"
              text-anchor="#{shape.anchor}" dx="#{shape.dx}em" dy="#{shape.dy}em"
              writing-mode="#{shape.writing_mode}"
              s:attribute="#{shape.name}"
              class="#{shape.layer || ''}">#{shape.name}</text>

        """
      when 'line'
        return """
        <line x1="#{shape.x1}" x2="#{shape.x2}"
              y1="#{shape.y1}" y2="#{shape.y2}"
              stroke-width="#{shape.lineWidth}"
              class="#{shape.layer || ''}"/>

        """
      when 'rectangle'
        return """
        <rect x="#{shape.x1}" y="#{shape.y1}"
              width="#{Math.abs(shape.x2 - shape.x1)}"
              height="#{Math.abs(shape.y2 - shape.y1)}"
              stroke-width="#{shape.lineWidth}"
              class="#{shape.layer || ''}"/>

        """
      when 'circle'
        return """
        <circle cx="#{shape.x}" cy="#{shape.y}"
                r="#{shape.radius}" fill="#{shape.fill}"
                stroke-width="#{shape.lineWidth}"
                class="#{shape.layer || ''}"/>

        """
      when 'arc'
        return """
        <path d="#{describeArc(shape)}" stroke-width="#{shape.lineWidth}"
              class="#{shape.layer || ''}"/>

        """
      when 'poly'
        return """
        <path d="#{describePoly(shape)}" fill="#{shape.fill}"
              stroke-width="#{shape.lineWidth}"
              class="#{shape.layer || ''}"/>

        """

  _preprocessShape: (shape, settings, hideAttributes) ->
    if shape.lineWidth?
      if shape.lineWidth == 0
        shape.lineWidth = settings.lineWidth.default
    if shape.layer?
      shape.layer = shape.layer.join(' ')
    if shape.fill?
      shape.fill = if shape.fill == 'background' then '#000' else 'none'
    if shape.valign?
      switch shape.valign
        when "bottom"
          shape.dy = 0
        when "center"
          shape.dy = .4
        when "top"
          shape.dy = 1
    if shape.halign?
      switch shape.halign
        when "left"
          shape.anchor = "start"
        when "right"
          shape.anchor = "end"
        when "center"
          shape.anchor = "middle"
    if shape.kind == 'attribute'
      shape.writing_mode = 'lr'
      shape.dx = 0
    if shape.kind == 'pin'
      shape.xdir = 0
      shape.ydir = 0
      switch shape.orientation
        when 'up'
          shape.position = 'bottom'
          shape.ydir = -1
        when 'down'
          shape.position = 'top'
          shape.ydir = 1
        when 'right'
          shape.position = 'left'
          shape.xdir = 1
        when 'left'
          shape.position = 'right'
          shape.xdir = -1

    if shape.kind == 'attribute'
      if hideAttributes
        shape.visible = false
      switch shape.name
        when 'refDes'
          shape.fontSize ?= settings.fontSize.refDes
          shape.name = 'ref'
        when 'value'
          shape.fontSize ?= settings.fontSize.value
        else
          shape.fontSize ?= settings.fontSize.default

  _getBoundingBox: (hasShapes) ->
    [minx, miny, maxx, maxy] = boundingBox(() ->
      for shape in hasShapes.shapes
        yield from iterPoints(shape)
    )
    width = maxx - minx
    height = maxy - miny
    return [minx, miny, width, height]

module.exports = SvgGenerator
