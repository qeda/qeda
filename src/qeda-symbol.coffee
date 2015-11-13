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
  # Add attribute object
  #
  addAttribute: (name, attribute) ->
    attribute.name = name
    @attributes[name] = @addShape 'attribute',  attribute

  #
  # Add rectangle object
  #
  addLine: (line) ->
    @addShape 'line', line

  #
  # Add pin object
  #
  addPin: (pin) ->
    @addShape 'pin', pin

  #
  # Add rectangle object
  #
  addRectangle: (rectangle) ->
    @addShape 'rectangle', rectangle

  #
  # Add arbitrary shape object
  #
  addShape: (kind, shape) ->
    obj =
      kind: kind
    for own prop of shape
      obj[prop] = shape[prop]
    @shapes.push obj
    obj

  #
  # Flip vertically
  #
  invertVertical: ->
    props = ['y', 'y1', 'y2', 'height']
    for shape in @shapes
      for prop in props
        if shape[prop]? then shape[prop] *= -1

  #
  # Convert inner units to physical (mm, mil etc.)
  #
  resize: (gridSize) ->
    props = ['x', 'x1', 'x2', 'y', 'y1', 'y2', 'width', 'height', 'length']
    for shape in @shapes
      for prop in props
        if shape[prop]? then shape[prop] *= gridSize

module.exports = QedaSymbol
