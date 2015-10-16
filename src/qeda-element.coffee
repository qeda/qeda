QedaSymbol = require './qeda-symbol'
QedaPattern = require './qeda-pattern'

#
# Class for electronic component
#
class QedaElement
  #
  # Constructor
  #
  constructor: (@lib, def) ->
    @mergeObjects this, def

    @refDes = 'REF' # Should be overriden in styling script
    @symbol = new QedaSymbol this
    @patterns = []

    @pins = []
    for pin of @pinout
      unless Array.isArray @pinout[pin] then @pinout[pin] = [@pinout[pin]]
      for pinNum in @pinout[pin]
        @pins[pinNum] =
          name: pin

    unless Array.isArray @package
      @package = [@package]
    for p in @package
      if typeof p is 'object'
        @addPattern p
      else if typeof p is 'string'
        if @[p]? then @addPattern @[p]

    handler = require "./element/#{@lib.elementStyle}"
    handler this

  #
  # Calculate actual layouts
  #
  calculate: (gridSize) ->
    @_calculated ?= false
    if @_calculated then return
    
    # Apply symbol handler
    if @schematics?.symbol?
      for def in @lib.symbolDefs
        cap = def.regexp.exec @schematics.symbol
        if cap
          handler = require "./symbol/#{@lib.symbolStyle}/#{def.handler}"
          handler(@symbol, cap[1..]...)

    @symbol.calculate gridSize

    # Apply pattern handlers
    for pattern in @patterns
      for def in @lib.patternDefs
        cap = def.regexp.exec pattern.name
        if cap
          handler = require "./pattern/#{@lib.patternStyle}/#{def.handler}"
          handler(pattern, cap[1..]...)

    @_calculated = true

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
  # Add pattern
  #
  addPattern: (packageDef) ->
    unless packageDef.pattern?
      return
    @patterns.push(new QedaPattern this, packageDef.pattern)

  #
  # Return pin definition
  #
  pinDef: (pinNum) ->
    @pins[pinNum]

module.exports = QedaElement
