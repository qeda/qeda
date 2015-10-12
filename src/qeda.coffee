KicadGenerator = require './kicad-generator'

class Qeda
  #
  # Constructor
  #
  constructor: (settings = {}) ->
    @elementStyle = 'default'
    @symbolStyle = 'default'
    @patternStyle = 'default'
    @symbol =
      units: 'mm'
      gridSize: 5
      textSize: 1
    @mergeObjects this, settings

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

  #
  # Calculate patterns' dimensions according to settings
  #
  calculatePatterns: (units = 'mm') ->
    k = 1
    if units is 'mil' then k = 100/2.54

  #
  # Calculate symbols' dimensions according to settings
  #
  calculateSymbols: (units = 'mm') ->
    k = 1
    if @symbol.units is 'mm' and units is 'mil'
      k = 100/2.54
    else if @symbol.units is 'mil' and units is 'mm'
      k = 2.54/100
    @symbol.gridSize *= k
    @symbol.textSize = Math.round(@symbol.textSize * @symbol.gridSize)
    #for e in @elements

  #
  # Generate library in KiCad format
  #
  generateKicad: (name) ->
    kicad = new KicadGenerator(this)
    kicad.generate name

  #
  # Merge two objects
  #
  mergeObjects: (dest, src) ->
    for k, v of src
      if typeof v is 'object' and dest.hasOwnProperty k
        @mergeObjects dest[k], v
      else
        dest[k] = v

module.exports = Qeda
