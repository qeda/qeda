#
# Class for schematics symbol
#
class QedaSymbol
  constructor: (@element) ->
    @shapes = []
    @attributes = []

  #
  #
  #
  addAttribute: (key, attribute) ->
    shape =
      type: 'attribute'
    for own prop of attribute
      shape[prop] = attribute[prop]
    @shapes.push shape
    @attributes[key] = shape

  #
  # Add pin object
  #
  addPin: (pin) ->
    shape =
      type: 'pin'
    for own prop of pin
      shape[prop] = pin[prop]
    @shapes.push shape

  addRectangle: (rectangle) ->
    shape =
      type: 'rectangle'
    for own prop of rectangle
      shape[prop] = rectangle[prop]
    @shapes.push shape

  #
  # Get attribute
  #
  attribute: (key) ->
    @attributes[key]

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

  invertVertical: ->
    for shape in @shapes
      if shape.y? then shape.y *= -1
      if shape.height? then shape.height *= -1

  #
  # Get pin definition
  #
  pinDef: (pinNum) ->
    @element.pinDef pinNum


module.exports = QedaSymbol
