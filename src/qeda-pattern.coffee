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


module.exports = QedaPattern
