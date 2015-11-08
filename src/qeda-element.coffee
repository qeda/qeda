fs = require 'fs'
yaml = require 'js-yaml'

QedaSymbol = require './qeda-symbol'
QedaPattern = require './qeda-pattern'

#
# Class for electronic component
#
class QedaElement
  #
  # Constructor
  #
  constructor: (@library, definition) ->
    @mergeObjects this, definition

    if @alias?
      @aliases ?= []
      @aliases.concat @alias.replace(/\s+/g, '').split(',')
    if @suffix?
      @aliases ?= []
      suffixes = @suffix.replace(/\s+/g, '').split(',')
      for suffix in suffixes
        alias = @name + suffix
        if @aliases.indexOf(alias) is -1 then @aliases.push alias

    # Find longest alias
    @longestAlias = @name
    if @alias?
      for alias in @alias
        if alias.length > @longestAlias.length then @longestAlias = alias

    @refDes = 'REF' # Should be overriden in element handler
    @symbols = [] # Array of symbols (one for single part or several for multi-part)
    @pattern = new QedaPattern this

    @pins = [] # Array of pin objects
    @pinGroups = [] # Array of pin groups

    # Grid-array row letters
    @_letters = ['', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'R', 'T', 'U', 'V', 'W', 'Y']
    last = @_letters.length - 1
    for i in [1..last]
      for j in [i..last]
        @_letters.push @_letters[i] + @_letters[j]

    @delimiter = {}
    for key, value of @joint
      groups = @parseGroups key
      for group in groups
        @delimiter[group] = value

    # Create pin objects and groups
    for name, value of @pinout
      pins = @_addPins name, value
      @pinGroups[name] = pins
      if typeof value is 'object' then continue
      for number in pins
        @pins[number] = @_pinObj number, name

    # Forming groups
    for key, value of @groups
      @pinGroups[key] = @_concatenateGroups value

    if @parts? # Multi-part element
      for name, part of @parts
        @symbols.push new QedaSymbol(this, @parseGroups(part), name)
    else # Single-part element
      part = []
      if @groups?
        part.push key for key of @groups
      else
        part.push key for key of @pinout
      @symbols.push new QedaSymbol(this, part)

  #
  # Check whether number is float
  #
  isFloat: (n) ->
    Number(n) and (n % 1 isnt 0)

  #
  # Merge two objects
  #
  mergeObjects: (dest, src) ->
    for k, v of src
      if typeof v is 'object' and (not Array.isArray v) and dest.hasOwnProperty k
        @mergeObjects dest[k], v
      else
        dest[k] = v

  #
  # Parse group list
  #
  parseGroups: (groups) ->
    result = []
    groups = groups.replace(/\s+/g, '').split(',')
    for group in groups
      cap = /(\w+)(\d+)-(\d+)/.exec group
      if cap
        for i in [cap[2]..cap[3]]
          result.push cap[1] + i
      else
        result.push group
    result

  #
  # Generate symbols and patterns
  #
  render: ->
    @_rendered ?= false
    if @_rendered then return
    # Apply elemend wide handler
    handler = require "./element/#{@library.elementStyle}"
    handler this

    # Symbols processing
    for symbol in @symbols
      # Apply symbol handler
      if @schematic?.symbol?
        handler = require "./symbol/#{@library.symbolStyle}/#{@schematic.symbol.toLowerCase()}"
        handler symbol

    # Pattern processing
    if @housing?.outline?
      cap = @housing.outline.split(' ')
      dirName = cap.shift().toLowerCase()
      fileName = cap.shift().toLowerCase()
      try
        outline = yaml.safeLoad fs.readFileSync(__dirname + "/outline/#{dirName}/#{fileName}.yaml")
      catch error
        console.error "Loading outline '#{@housing.outline}': Error: #{error.message}"
        process.exit 1
      loop
        for key, value of outline
          if (typeof value is 'number') or (typeof value is 'string')
            @housing[key] = value
        if cap.length is 0 then break
        outline = outline[cap.shift()]
        unless outline? then break

    @_convertDimensions @housing
    handler = require "./pattern/#{@library.patternStyle}/#{@pattern.handler}"
    handler @pattern, @housing
    @pattern.name ?= @housing.pattern

    @_rendered = true

  #
  # Add pin objects
  #
  _addPins: (key, value) ->
    result = []
    if typeof value is 'object'
      for name, numbers of value
        pins = @_addPins name, numbers
        if @delimiter[key] then name = key + @delimiter[key] + name
        for number in pins
          @pins[number] = @_pinObj number, name
        result = result.concat pins
    else
      if typeof value is 'number' then value = value.toString()
      numbers = value.replace(/\s+/g, '').split(',')
      for number in numbers
        cap = /([A-Z]*)(\d+)-([A-Z]*)(\d+)/.exec number
        unless cap
          result.push number
        else
          row1 = @_letters.indexOf cap[1]
          row2 = @_letters.indexOf cap[3]
          col1 = parseInt cap[2]
          col2 = parseInt cap[4]
          for row in [row1..row2]
            for col in [col1..col2]
              result.push @_letters[row] + col
    result

  _concatenateGroups: (groups) ->
    result = []
    groups = @parseGroups groups
    for group in groups
      pinGroup = @pinGroups[group]
      if pinGroup? then result = result.concat pinGroup
    result

  #
  # Make dimensions more convenient
  #
  _convertDimensions: (housing) ->
    for key, value of housing
      if typeof value is 'string'
        value = value.replace(/\s+/g, '').split('-').map (a) -> parseFloat(a)
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
    obj = @pins[number]
    if obj?
      obj.name += '/' +  name
    else
      obj =
        name: name
        number: number

    if @properties?
      props = ['analog', 'bidir', 'ground', 'in', 'inverted', 'nc', 'out', 'passive', 'power', 'z']
      for prop in props
        if @properties[prop]?
          pins = @parseGroups @properties[prop]
          obj[prop] ?= false
          if (pins.indexOf(name) isnt -1) then obj[prop] = true
    obj

module.exports = QedaElement
