#
# Class for schematics symbol
#
class QedaSymbol
  #
  # Constructor
  #
  constructor: (element, @name, part) ->
    @settings = element.library.symbol
    @shapes = []
    @attributes = []
    @currentLineWidth = 0
    sides = ['left', 'right', 'top', 'bottom']
    schematic = element.schematic
    pins = element.pins

    if part?
      @part = {}
      for k, v of element.pinGroups
        if part.indexOf(k) isnt -1 then @part[k] = v

    for side in sides
      @[side] = []
      if schematic[side]?
        groups = element.parseMultiple schematic[side]
        if part? then groups = groups.filter((v) => part.indexOf(v) isnt -1)
        for group in groups
          if element.pinGroups[group]?
            pinGroup = element.pinGroups[group]
            if @[side].length and (not schematic.simpified)
              @[side].push '--' # Insert gap
            @[side] = @[side].concat pinGroup
    # Divide common pins between left and right evenly
    both = @left.filter((v) => (v isnt '--') and (@right.indexOf(v) isnt -1))
    delta = Math.ceil((@right.length - @left.length + both.length) / 2)
    toLeft = both[0..(delta-1)]
    toRight = both[delta..]
    @left = @left.filter((v) => toRight.indexOf(v) is -1)
    @right = @right.filter((v) => toLeft.indexOf(v) is -1)

    # Divide common pins between top and bottom evenly
    both = @top.filter((v) => (v isnt '--') and (@bottom.indexOf(v) isnt -1))
    delta = Math.ceil((@bottom.length - @top.length + both.length) / 2)
    toTop = both[0..(delta-1)]
    toBottom = both[delta..]
    @top = @top.filter((v) => toBottom.indexOf(v) is -1)
    @bottom = @bottom.filter((v) => toTop.indexOf(v) is -1)

    if schematic.simpified then schematic.showPinNames ?= false

    @x = 0
    @y = 0
    @cx = 0
    @cy = 0

  #
  # Align number to grid
  #
  alignToGrid: (n, method = 'round') ->
    Math[method](n / @settings.gridSize) * @settings.gridSize

  #
  # Add arc
  #
  arc: (x, y, radius, start, end) ->
    @_addShape 'arc', { x: @cx + x, y: @cy + y, radius: radius, start: start, end: end }
    this

  #
  # Add arrow
  #
  arrow: (x1, y1, x2, y2, width) ->
    a = Math.atan( (y2 - y1) / (x2 - x1) )
    x11 = x1 + width*Math.sin(a)/2
    y11 = y1 - width*Math.cos(a)/2
    x12 = x1 - width*Math.sin(a)/2
    y12 = y1 + width*Math.cos(a)/2
    @poly x11, y11, x2, y2, x12, y12, 'background'

  #
  # Add attribute
  #
  attribute: (name, attribute) ->
    attribute.name = name
    attribute.fontSize ?= @settings.fontSize[name] ? @settings.fontSize.default
    @attributes[name] = @_addShape 'attribute',  attribute
    this

  #
  # Change center point
  #
  center: (x, y) ->
    @cx = x
    @cy = y
    this

  #
  # Add circle
  #
  circle: (x, y, radius, fill = 'none') ->
    @_addShape 'circle', { x: @cx + x, y: @cy + y, radius: radius, fill: fill }
    this

  #
  # Add dot
  #
  dot: (x, y) ->
    @_addShape 'line', { x1: @cx + x, y1: @cy + y, x2: @cx + x, y2: @cy + y }
    this

  #
  # Add icon
  #
  icon: (x, y, iconObj) ->
    iconObj.draw x, y
    this

  #
  # Flip vertically
  #
  invertVertical: ->
    props = ['y', 'y1', 'y2', 'height']
    for shape in @shapes
      for prop in props
        if shape[prop]? then shape[prop] *= -1
      if shape['points']?
        shape['points'] = shape['points'].map((v, i) -> if i % 2 is 1 then -v else v)

  #
  # Add line
  #
  line: (x1, y1, x2, y2) ->
    if (x1 isnt x2) or (y1 isnt y2)
      @_addShape 'line', { x1: @cx + x1, y1: @cy + y1, x2: @cx + x2, y2: @cy + y2 }
    this

  #
  # Line to current position
  #
  lineTo: (x, y) ->
    @line @x, @y, x, y
    @moveTo x, y

  #
  # Set current line width
  #
  lineWidth: (lineWidth) ->
    @currentLineWidth = lineWidth
    this

  #
  # Change current position
  #
  moveTo: (x, y) ->
    @x = x
    @y = y
    this

  #
  # Add pin
  #
  pin: (pin) ->
    pin.fontSize ?= @settings.fontSize.pin
    pin.space ?= @settings.space.pin
    pin.x = @cx + pin.x
    pin.y = @cy + pin.y
    @_addShape 'pin', pin
    this

  #
  # Add polyline/polygon
  #
  poly: (points..., fill) ->
    count = points.length/2
    for i in [0..(count - 1)]
      points[2*i] = @cx + points[2*i]
      points[2*i + 1] = @cy + points[2*i + 1]
    # Close polyline
    if (points[0] != points[points.length - 2]) and (points[1] != points[points.length - 1])
      points.push points[0]
      points.push points[1]
    @_addShape 'poly', { points: points, fill: fill }
    this

  #
  # Add polyline
  #
  polyline: (points...) ->
    @poly points..., 'none'

  #
  # Add rectangle
  #
  rectangle: (x1, y1, x2, y2, fill = 'none') ->
    @_addShape 'rectangle', { x1: @cx + x1, y1: @cy + y1, x2: @cx + x2, y2: @cy + y2, fill: fill }
    this

  #
  # Resize symbol to new grid size
  #
  resize: (gridSize, needRound = false) ->
    factor = gridSize / @settings.gridSize
    props = ['x', 'x1', 'x2', 'y', 'y1', 'y2', 'width', 'height', 'length', 'lineWidth', 'fontSize', 'space', 'radius']
    for shape in @shapes
      for prop in props
        if shape[prop]?
           value = shape[prop] * factor
           if needRound then value = Math.round value
           shape[prop] = value
      if shape['points']?
        shape['points'] = shape['points'].map((v) -> v * factor)
        if needRound then shape['points'] = shape['points'].map((v) -> Math.round(v))

  #
  # Add text string
  #
  text: (text) ->
    text.fontSize ?= @settings.fontSize.default
    text.angle ?= 0
    @_addShape 'text',  text
    this

  #
  # Get text height
  #
  textWidth: (text, textType = 'default') ->
    @settings.fontSize[textType] * text.length

  #
  # Add arbitrary shape object
  #
  _addShape: (kind, shape) ->
    obj =
      kind: kind
    for own prop of shape
      obj[prop] = shape[prop]
    obj.lineWidth ?= @currentLineWidth
    @shapes.push obj
    obj

module.exports = QedaSymbol
