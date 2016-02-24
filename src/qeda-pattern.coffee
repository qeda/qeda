crc = require 'crc'

#
# Class for footprint pattern
#
class QedaPattern
  #
  # Constructor
  #
  constructor: (element) ->
    @settings = element.library.pattern
    @crc32 = @_calcCrc element.housing
    @shapes = []
    @currentLayer = ['topCopper']
    @currentLineWidth = 0
    @type = 'smd'
    @attributes = {}
    @pads = {}
    @x = 0
    @y = 0
    @cx = 0
    @cy = 0

  #
  # Add attribute
  #
  attribute: (name, attribute) ->
    attribute.name = name
    attribute.x = @cx + attribute.x
    attribute.y = @cy + attribute.y
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
  circle: (x, y, radius) ->
    @_addShape 'circle', { x: @cx + x, y: @cy + y, radius: radius }
    this

  #
  # Check whether two patterns are equal
  #
  isEqualTo: (pattern) ->
    @crc32 is pattern.crc32

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
    pad.x = @cx + pad.x
    pad.y = @cy + pad.y
    @pads[name] = @_addPad pad
    this

  #
  # Add polarity mark
  #
  polarityMark: (x, y, position = 'left') ->
    d = 0.5
    switch position
      when 'left' then x -= d/2
      when 'right' then x += d/2
      when 'top' then y -= d/2
      when 'bottom' then y += d/2
      when 'topLeft'
        x -= d/2
        y -= d/2
      when 'topRight'
        x += d/2
        y -= d/2
      when 'bottomLeft'
        x -= d/2
        y += d/2
      when 'bottomRight'
        x += d/2
        y += d/2

    switch @settings.polarityMark
      when 'dot'
        r = d/2
        oldLineWidth = @currentLineWidth
        @lineWidth r
        @circle x, y, r/2
        @lineWidth oldLineWidth

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

  _calcCrc: (housing) ->
    sum = 0
    exclude = ['suffix']
    for key in Object.keys(housing)
      if exclude.indexOf(key) isnt -1 then continue
      sum = crc.crc32 "#{key}=#{housing[key]}", sum
    sum

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
  # Set current line width
  #
  _setLineWidth: (lineWidth) ->
    @currentLineWidth = lineWidth

module.exports = QedaPattern
