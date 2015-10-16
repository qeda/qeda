#
# Class for footprint pattern
#
class QedaPattern
  constructor: (@element, @name) ->

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
