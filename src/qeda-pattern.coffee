#
# Class for footprint pattern
#
class QedaPattern
  #
  # Constructor
  #
  constructor: (@element, @housing) ->
    @name = @housing.pattern
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
  # Merge two objects
  #
  mergeObjects: (dest, src) ->
    for k, v of src
      if typeof v is 'object' and dest.hasOwnProperty k
        @mergeObjects dest[k], v
      else
        dest[k] = v

module.exports = QedaPattern
