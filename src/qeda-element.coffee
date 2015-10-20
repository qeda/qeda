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
    @symbol.settings = @lib.symbol
    @patterns = []

    @pins = []
    for pinName of @pinout
      pinNumbers = if Array.isArray @pinout[pinName] then @pinout[pinName] else [@pinout[pinName]]
      for pinNumber in pinNumbers
        @pins[pinNumber] = @_pinObj pinNumber, pinName

    unless Array.isArray @housing
      @housing = [@housing]
    for h in @housing
      if typeof h is 'object'
        @addPattern h
      else if typeof h is 'string'
        if @[h]? then @addPattern @[h]

  #
  # Add pattern
  #
  addPattern: (housing) ->
    unless housing.pattern?
      return
    pattern = new QedaPattern this, housing
    pattern.settings = @lib.pattern
    @patterns.push pattern

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
      if pattern.housing?.outline?
        outline = pattern.housing.outline
        for def in @lib.outlineDefs
          cap = def.regexp.exec outline
          if cap
            handler = require "./outline/#{def.handler}"
            handler(pattern.housing, cap[1..]...)
      @_convertDimensions pattern.housing
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
  # Make dimensions more convenient
  #
  _convertDimensions: (housing) ->
    for key, value of housing
      if Array.isArray(value) and value.length > 0
        min = value[0]
        max = if value.length > 1 then value[1] else min
        nom = (max + min) / 2
        tol = max - min
        housing[key] = { min: min,  max: max,  nom: nom, tol: tol }

  #
  # Generate pin object
  #
  _pinObj: (number, name) ->
    obj =
      name: name
      number: number

    if @properties?
      props = ['ground', 'in', 'inverted', 'out', 'power']
      for prop in props
        if @properties[prop]?
          pins = if Array.isArray @properties[prop] then @properties[prop] else [@properties[prop]]
          obj[prop] = (pins.indexOf(name) isnt -1)
    obj

module.exports = QedaElement
