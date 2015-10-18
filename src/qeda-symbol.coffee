#
# Class for schematics symbol
#
class QedaSymbol
  constructor: (@element) ->
    @shapes = []
    @attributes = []

  #
  # Add attribute object
  #
  addAttribute: (key, attribute) ->
    @attributes[key] = @addShape 'attribute',  attribute

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
  #
  #
  invertVertical: ->
    for shape in @shapes
      if shape.y? then shape.y *= -1
      if shape.height? then shape.height *= -1

module.exports = QedaSymbol
