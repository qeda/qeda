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

    @refDes = 'REF' # Should be overriden in element handler
    @symbol = new QedaSymbol this
    @patterns = []

    @pins = []
    for pinName of @pinout
      pinNumbers = if Array.isArray @pinout[pinName] then @pinout[pinName] else [@pinout[pinName]]
      for pinNumber in pinNumbers
        @pins[pinNumber] = @_pinObj pinNumber, pinName

    unless Array.isArray @package
      @package = [@package]
    for p in @package
      if typeof p is 'object'
        @addPattern p
      else if typeof p is 'string'
        if @[p]? then @addPattern @[p]

  #
  # Calculate actual layouts
  #
  calculate: (gridSize) ->
    @_calculated ?= false
    if @_calculated then return

    # Apply elemend wide handler
    handler = require "./element/#{@lib.elementStyle}"
    handler this

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
  # Generate pin object
  #
  _pinObj: (number, name) ->
    obj =
      name: name
      number: number

    features = ['ground', 'in', 'inverted', 'out', 'power']
    for feature in features
      if @pinFeatures[feature]?
        pins = if Array.isArray @pinFeatures[feature] then @pinFeatures[feature] else [@pinFeatures[feature]]
        obj[feature] = (pins.indexOf(name) isnt -1)
    obj

module.exports = QedaElement
