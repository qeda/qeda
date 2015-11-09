#
# Class for schematics symbol
#
class QedaSymbol
  #
  # Constructor
  #
  constructor: (@element, @groups, @name) ->
    @settings = @element.library.symbol
    @schematic = @element.schematic
    @shapes = []
    @attributes = []
    sides = ['left', 'right', 'top', 'bottom']
    for side in sides
      @[side] = []
      if @schematic[side]?
        groups = @element.parseMultiple @schematic[side]
        for group in groups
          pinGroup = @element.pinGroups[group]
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
    for shape in @shapes
      if shape.y? then shape.y *= -1
      if shape.height? then shape.height *= -1

  #
  # Convert inner units to physical (mm, mil etc.)
  #
  resize: (gridSize) ->
    for shape in @shapes
      if shape.x? then shape.x *= gridSize
      if shape.y? then shape.y *= gridSize
      if shape.length? then shape.length *= gridSize
      if shape.width? then shape.width *= gridSize
      if shape.height? then shape.height *= gridSize


module.exports = QedaSymbol
