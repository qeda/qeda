#
# Class for footprint pattern
#
class QedaPattern
  #
  # Constructor
  #
  constructor: (element) ->
    @handler = element.housing.pattern.toLowerCase()
    @settings = element.library.pattern
    @shapes = []
    @layer = 'top'
    @lineWidth = 0
    @type = 'smd'
    @attributes = {}

  #
  # Add attribute object
  #
  addAttribute: (name, attribute) ->
    attribute.name = name
    @attributes[name] = @addShape 'attribute',  attribute

  #
  # Add circle object
  #
  addCircle: (circle) ->
    @addShape 'circle', circle

  #
  # Add circle object
  #
  addLine: (line) ->
    @addShape 'line', line

  #
  # Add pad object
  #
  addPad: (pad) ->
    if pad.type isnt 'smd' then @type = 'through-hole'
    @addShape 'pad', pad

  #
  # Add rectangle object
  #
  addRectangle: (rectangle) ->
    x1 = rectangle.x
    y1 = rectangle.y
    x2 = rectangle.x + rectangle.width
    y2 = rectangle.y + rectangle.height
    @addLine { x1: x1, y1: y1, x2: x2, y2: y1 }
    @addLine { x1: x2, y1: y1, x2: x2, y2: y2 }
    @addLine { x1: x1, y1: y2, x2: x2, y2: y2 }
    @addLine { x1: x1, y1: y1, x2: x1, y2: y2 }

  #
  # Add arbitrary shape object
  #
  addShape: (kind, shape) ->
    obj =
      kind: kind
    for own prop of shape
      obj[prop] = shape[prop]
    obj.layer ?= @layer
    obj.lineWidth ?= @lineWidth
    @shapes.push obj
    obj

  #
  # Add text object
  #
  addText: (text) ->
    @addShape 'text',  text

  #
  # Merge two objects
  #
  mergeObjects: (dest, src) ->
    for k, v of src
      if typeof v is 'object' and dest.hasOwnProperty k
        @mergeObjects dest[k], v
      else
        dest[k] = v

  #
  # Set current layer
  #
  setLayer: (layer) ->
    @layer = layer

  #
  # Set current line width
  #
  setLineWidth: (lineWidth) ->
    @lineWidth = lineWidth


module.exports = QedaPattern
