class Qeda
  #
  # Constructor
  #
  constructor: ->
    @symbolStyle = 'default'
    @patternStyle = 'default'

  #
  # Mixin definition
  #
  mixin = (fields) =>
    for name, field of fields
      this::[name] = field
    for name, field of fields
      # Mixin constructor starts with '_init'
      if name.indexOf('_init') is 0 and typeof field is 'function'
        this::[name]()

  mixin require './mixins/element'
  mixin require './mixins/kicad'

  #
  # Merge two objects
  #
  mergeObjects: (dest, src) ->
    for k, v of src
      if typeof v is 'object' and dest.hasOwnProperty k
        @mergeObjects dest[k], v
      else
        dest[k] = v

  setSymbolStyle: (style) ->
    @symbolStyle = style.toLowerCase()

  setPatternStyle: (style) ->
    @patternStyle = style.toLowerCase()

module.exports = Qeda
