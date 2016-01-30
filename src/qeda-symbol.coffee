#
# Class for schematics symbol
#
class QedaSymbol
  #
  # Constructor
  #
  constructor: (element, @groups, @name) ->
    @settings = element.library.symbol
    @shapes = []
    @attributes = []
    @currentLineWidth = 0
    sides = ['left', 'right', 'top', 'bottom']
    schematic = element.schematic
    for side in sides
      @[side] = []
      if schematic[side]?
        groups = element.parseMultiple schematic[side]
        for group in groups
          pinGroup = element.pinGroups[group]
          if (@groups.indexOf(group) isnt -1) and pinGroup?
            if @[side].length > 0
              @[side].push '-' # Insert gap
            @[side] = @[side].concat pinGroup

    both = @left.filter((a) => (a isnt '-') and (@right.indexOf(a) isnt -1))
    delta = Math.ceil((@right.length - @left.length + both.length) / 2)
    toLeft = both[0..(delta-1)]
    toRight = both[delta..]
    @left = @left.filter((a) => toRight.indexOf(a) is -1)
    @right = @right.filter((a) => toLeft.indexOf(a) is -1)

  #
  # Align number to grid
  #
  alignToGrid: (n) ->
    Math.ceil(n / @settings.gridSize) * @settings.gridSize

  #
  # Add attribute
  #
  attribute: (name, attribute) ->
    attribute.name = name
    attribute.fontSize ?= @settings.fontSize[name] ? @settings.fontSize.default
    @attributes[name] = @_addShape 'attribute',  attribute
    this

  #
  # Add circle
  #
  circle: (x, y, radius) ->
    @_addShape 'circle', { x: x, y: y, radius: radius }
    this

  #
  # Flip vertically
  #
  invertVertical: ->
    props = ['y', 'y1', 'y2', 'height']
    for shape in @shapes
      for prop in props
        if shape[prop]? then shape[prop] *= -1

  #
  # Add line
  #
  line: (x1, y1, x2, y2) ->
    @_addShape 'line', { x1: x1, y1: y1, x2: x2, y2: y2 }
    this

  #
  # Set current line width
  #
  lineWidth: (lineWidth) ->
    @currentLineWidth = lineWidth
    this

  #
  # Add pin
  #
  pin: (pin) ->
    pin.fontSize ?= @settings.fontSize.pin
    pin.space ?= @settings.space.pin
    @_addShape 'pin', pin
    this

  #
  # Add rectangle
  #
  rectangle: (x1, y1, x2, y2, fill = 'none') ->
    @_addShape 'rectangle', { x1: x1, y1: y1, x2: x2, y2: y2, fill: fill }
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
