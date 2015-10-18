#
# Class for footprint pattern
#
class QedaPattern
  #
  # Constructor
  #
  constructor: (@element, @name) ->
    @shapes = []

  #
  # Add pad object
  #
  addPad: (pad) ->
    @addShape 'pad', pad

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
  # Set current layer
  #
  ###
  setLayer: (layer) ->
    @layer = layer
    @pattern.push tag: 'layer', name: layer
    #console.log 'setLayer'
  ###

  #
  # Add rectangle to current layer
  #
  ###
  rect: (x, y, w, h) ->
    @pattern.push tag: 'rect', x: x, y: y, w: w, h: h
    #console.log 'rect'
  ###

module.exports = QedaPattern
