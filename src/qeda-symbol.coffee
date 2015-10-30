#
# Class for schematics symbol
#
class QedaSymbol
  #
  # Constructor
  #
  constructor: (@element, @name, @part) ->
    @settings = @element.library.symbol
    @schematic = @element.schematic
    @shapes = []
    @attributes = []
    sides = ['left', 'right', 'top', 'bottom']
    for side in sides
      @[side] = []
      if @schematic[side]?
        groups = @schematic[side]
        unless Array.isArray groups then groups = [groups]
        for group in groups
          pinGroup = @element.pinGroups[group]
          if (@part.indexOf(group) isnt -1) and pinGroup?
            if @[side].length > 0
              @[side].push '-' # Insert gap
            @[side] = @[side].concat pinGroup

    both = @left.filter((n) => (n isnt '-') and (@right.indexOf(n) isnt -1))
    delta = Math.ceil((@left.length + both.length - @right.length) / 2)
    left = both[0..(delta-1)]
    right = both[delta..]
    @left = @left.filter((n) => right.indexOf(n) is -1)
    @right = @right.filter((n) => left.indexOf(n) is -1)

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
  # Convert inner units to physical (mm, mil etc.)
  #
  calculate: (gridSize) ->
    @_calculated ?= false
    if @_calculated then return
    for shape in @shapes
      if shape.x? then shape.x *= gridSize
      if shape.y? then shape.y *= gridSize
      if shape.length? then shape.length *= gridSize
      if shape.width? then shape.width *= gridSize
      if shape.height? then shape.height *= gridSize
    @_calculated = true

  #
  # Flip vertically
  #
  invertVertical: ->
    for shape in @shapes
      if shape.y? then shape.y *= -1
      if shape.height? then shape.height *= -1

module.exports = QedaSymbol
