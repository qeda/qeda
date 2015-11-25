#
# Class for footprint pattern
#
class QedaPattern
  #
  # Constructor
  #
  constructor: (element) ->
    @settings = element.library.pattern
    @shapes = []
    @currentLayer = ['topCopper']
    @currentLineWidth = 0
    @type = 'smd'
    @attributes = {}
    @pads = {}
    @x = 0
    @y = 0

  #
  # Add attribute object
  #
  _addAttribute: (name, attribute) ->
    attribute.name = name
    @attributes[name] = @addShape 'attribute',  attribute

  #
  # Add pad object
  #
  _addPad: (pad) ->
    if pad.type isnt 'smd' then @type = 'through-hole'
    @_addShape 'pad', pad

  #
  # Add arbitrary shape object
  #
  _addShape: (kind, shape) ->
    obj =
      kind: kind
    for own prop of shape
      obj[prop] = shape[prop]
    obj.layer ?= @currentLayer
    obj.lineWidth ?= @currentLineWidth
    @shapes.push obj
    obj

  #
  # Add text object
  #
  _addText: (text) ->
    @addShape 'text',  text

  #
  # Merge two objects
  #
  _mergeObjects: (dest, src) ->
    for k, v of src
      if typeof v is 'object' and dest.hasOwnProperty k
        @mergeObjects dest[k], v
      else
        dest[k] = v

  #
  # Set current layer
  #
  _setLayer: (layer) ->
    unless Array.isArray(layer) then layer = [layer]
    @currentLayer = layer

  #
  # Set current line width
  #
  _setLineWidth: (lineWidth) ->
    @currentLineWidth = lineWidth

  #--------------------#
  #                    #
  #     Public API     #
  #                    #
  #--------------------#


  #
  # Add attribute
  #
  attribute: (name, attribute) ->
    attribute.name = name
    @attributes[name] = @_addShape 'attribute',  attribute
    this

  #
  # Add circle
  #
  circle: (x, y, radius) ->
    @_addShape 'circle', { x: x, y: y, radius: radius }
    this

  #
  # Set current layer(s)
  #
  layer: (layer) ->
    unless Array.isArray(layer) then layer = [layer]
    @currentLayer = layer
    this

  #
  # Add line
  #
  line: (x1, y1, x2, y2) ->
    @_addShape 'line', {x1: x1, y1: y1, x2: x2, y2: y2 }
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
    @_setLineWidth lineWidth
    this

  #
  # Change current position
  #
  moveTo: (x, y) ->
    @x = x
    @y = y
    this

  #
  # Add pad
  #
  pad: (name, pad) ->
    pad.name = name
    @pads[name] = @_addPad pad
    this

  #
  # Add rectangle
  #
  rectangle: (x1, y1, x2, y2) ->
    @save()
    @moveTo x1, y1
    @lineTo x2, y1
    @lineTo x2, y2
    @lineTo x1, y2
    @lineTo x1, y1
    @restore()

  #
  # Rectangle to current position
  #
  rectangleTo: (x, y) ->
    @rectangle @x, @y, x, y
    @moveTo x, y

  restore: ->
    unless @_origin? then return
    [@x, @y] = @_origin.pop()
    this

  save: ->
    @_origin ?= []
    @_origin.push [@x, @y]
    this

module.exports = QedaPattern
