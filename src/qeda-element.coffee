class QedaElement
  #
  # Constructor
  #
  constructor: (@lib, @def) ->
    @patterns = [] # All element patterns
    @pattern = []  # Current pattern
    @layer = 'top' # Current layer
    @name = @def.name
    @refDes = 'E' # Shoul be overriden in symbol handler

    if @def.symbol
      for s in @lib.symbolDefs
        cap = s.regexp.exec @def.symbol
        if cap
          handler = require "./symbol/#{@lib.symbolStyle}/#{s.handler}"
          handler(this, cap[1..]...)

    unless Array.isArray @def.package
      @def.package = [@def.package]
    for p in @def.package
      if typeof p is 'object'
        @addPattern p
      else if typeof p is 'string'
        if @def[p]? then @addPattern @def[p]

  #
  # Merge two objects
  #
  ###
  mergeObjects: (dest, src) ->
    for k, v of src
      if typeof v is 'object' and dest.hasOwnProperty k
        @mergeObjects dest[k], v
      else
        dest[k] = v
  ###

  #
  # Add pattern
  #
  addPattern: (packageDef) ->
    unless packageDef.pattern?
      return
    for p in @lib.patternDefs
      cap = p.regexp.exec packageDef.pattern
      if cap
        @patterns[cap[0]] = @pattern = []
        handler = require "./pattern/#{@lib.patternStyle}/#{p.handler}"
        handler(this, cap[1..]...)

  #
  # Set current layer
  #
  setLayer: (layer) ->
    @layer = layer
    @pattern.push tag: 'layer', name: layer
    #console.log 'setLayer'

  #
  # Add rectangle to current layer
  #
  rect: (x, y, w, h) ->
    @pattern.push tag: 'rect', x: x, y: y, w: w, h: h
    #console.log 'rect'


module.exports = QedaElement
