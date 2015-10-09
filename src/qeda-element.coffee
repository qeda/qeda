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

    @refDes = 'E' # Should be overriden in symbol or pattern handler
    @symbol = new QedaSymbol this
    @patterns = []

    @pins = []
    for pin of @pinout
      unless Array.isArray @pinout[pin] then @pinout[pin] = [@pinout[pin]]
      for pinNum in @pinout[pin]
        @pins[pinNum] =
          name: pin

    if @schematics?.symbol?
      for s in @lib.symbolDefs
        cap = s.regexp.exec @schematics.symbol
        if cap
          handler = require "./symbol/#{@lib.symbolStyle}/#{s.handler}"
          handler(@symbol, cap[1..]...)

    unless Array.isArray @package
      @package = [@package]
    for p in @package
      if typeof p is 'object'
        @addPattern p
      else if typeof p is 'string'
        if @[p]? then @addPattern @[p]

    handler = require "./element/#{@lib.elementStyle}.coffee"
    handler this

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
    pattern = new QedaPattern this
    for p in @lib.patternDefs
      cap = p.regexp.exec packageDef.pattern
      if cap
        handler = require "./pattern/#{@lib.patternStyle}/#{p.handler}"
        handler(pattern, cap[1..]...)
    @patterns.push pattern

  pinDef: (pinNum) ->
    @pins[pinNum]

module.exports = QedaElement
