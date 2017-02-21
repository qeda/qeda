fs = require 'fs'
yaml = require 'js-yaml'

QedaSymbol = require './qeda-symbol'
QedaPattern = require './qeda-pattern'
log = require './qeda-log'

#
# Class for electronic component
#
class QedaElement
  #
  # Constructor
  #
  constructor: (@library, description) ->
    @mergeObjects this, description

    if @suffix?
      @aliases ?= []
      newAliases = []
      suffixes = @suffix.replace(/\s+/g, '').split(',')
      newAliases = newAliases.concat(suffixes.map (v) => @name + v)
      for alias in @aliases
        newAliases = newAliases.concat(suffixes.map (v) => alias + v)
      newAliases = newAliases.filter (v) => @aliases.indexOf(v) is -1
      @aliases = @aliases.concat newAliases

    # Find longest alias
    @longestAlias = @name
    if @alias?
      for alias in @alias
        if alias.length > @longestAlias.length then @longestAlias = alias

    @refDes = 'REF' # Should be overriden in element handler
    @symbols = [] # Array of symbols (one for single part or several for multi-part)

    @pins = [] # Array of pin objects
    @pinGroups = [] # Array of pin groups

    # Grid-array row letters
    @gridLetters = ['', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'R', 'T', 'U', 'V', 'W', 'Y']
    # Make pairs
    last = @gridLetters.length - 1
    for i in [1..last]
      for j in [i..last]
        @gridLetters.push @gridLetters[i] + @gridLetters[j]

    # Process joint names
    @delimiter = {}
    for key, value of @joint
      groups = @parseMultiple key
      for group in groups
        @delimiter[group] = value

    # Create pin objects and groups
    if typeof @pinout is 'string' # Unnamed pins
      @schematic.simpified = true
      pins = @parseMultiple @pinout
      for pin in pins
        @_addPins pin, pin
    else
      @_addPins '', @pinout

    # Forming groups
    for key, value of @groups
      @pinGroups[key] = @_concatenateGroups value

    @_parseProperties()

    if @schematic?.options?
      options = @schematic.options.replace(/\s+/g, '').toLowerCase().split(',')
      for option in options
        @schematic[option] = true;

    # Create symbol(s)
    if @parts? # Multi-part element
      for name, part of @parts
        @symbols.push new QedaSymbol(this, name, @parseMultiple(part))
    else # Single-part element
      @symbols.push new QedaSymbol(this)

    # Create pattern
    if @housing? then @pattern = new QedaPattern this

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
  # Parse pin/group list
  #
  parseMultiple: (input) ->
    unless input? then return [0]
    result = []
    groups = input.toString().replace(/\s+/g, '').split(',')
    for group in groups
      cap = /(\D*)(\d+)-(\d+)/.exec group
      if cap
        begin = parseInt cap[2]
        end = parseInt cap[3]
        for i in [begin..end]
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

    # Symbols processing
    if @schematic?.symbol?
      paths = [
        "./symbol/#{@library.symbol.style.toLowerCase()}/#{@schematic.symbol.toLowerCase()}"
        "./symbol/default/#{@schematic.symbol.toLowerCase()}"
        process.cwd() + "/symbol/#{@schematic.symbol.toLowerCase()}"
      ]
      [handler, error] = @_firstHandler paths
      for symbol in @symbols
        log.start "Schematic symbol for '" + @name + (if symbol.name? then ': ' + symbol.name else '') + "'"
        if error then log.exception error
        handler symbol, this
        log.ok()

    # Pattern processing
    if @pattern?
      log.start "Land pattern for '#{@name}'"

      if @housing.options?
        options = @housing.options.replace(/\s+/g, '').toLowerCase().split(',')
        for option in options
          @housing[option] = true;

      @_convertDimensions @housing

      if @housing?.outline?
        cap = @housing.outline.split(' ')
        dirName = cap.shift().toLowerCase()
        fileName = cap.shift().toLowerCase()
        log.start "Outline '#{@housing.outline}'"
        try
          outline = yaml.safeLoad fs.readFileSync(__dirname + "/../share/outline/#{dirName}/#{fileName}.yaml")
        catch error
          log.error error.message
        dims = @_processOutline outline, cap
        @_convertDimensions dims
        for k, v of dims
          unless @housing[k]? then @housing[k] = v
        log.ok()

      @_legacy @housing # TODO: Remove in v1.0

      paths = [
        "./pattern/#{@library.pattern.style.toLowerCase()}/#{@housing.pattern.toLowerCase()}"
        "./pattern/default/#{@housing.pattern.toLowerCase()}"
        process.cwd() + "/pattern/#{@housing.pattern.toLowerCase()}"
      ]
      [handler, error] = @_firstHandler paths
      if error then log.exception error
      handler @pattern, this

      # Box
      @pattern.box =
        x: 0
        y: 0
        width: if @housing.bodyWidth? then @housing.bodyWidth.nom else 0
        length: if @housing.bodyLength? then @housing.bodyLength.nom else 0
        height: if @housing.height? then @housing.height.max else 0
      if @housing.bodyPosition?
        bodyPosition = @pattern.parsePosition @housing.bodyPosition
        @pattern.box.x = bodyPosition[0].x
        @pattern.box.y = bodyPosition[0].y

      log.ok()

    @_rendered = true

  #
  # Add pin objects
  #
  _addPins: (name, pinOrGroup) ->
    result = []
    unless pinOrGroup? then return result
    if typeof pinOrGroup is 'object' # Group of pins
      @pinGroups[name] ?= []
      for k, v of pinOrGroup
        pinName = if @delimiter[name]? then (name + @delimiter[name] + k) else k
        pins = @_addPins pinName, v
        @pinGroups[name] = @pinGroups[name].concat pins
        result = result.concat pins
    else # Pin number(s)
      if typeof pinOrGroup is 'number' then pinOrGroup = pinOrGroup.toString()
      numbers = pinOrGroup.replace(/\s+/g, '').split(',')
      for number in numbers
        cap = /([A-Z]*)(\d+)-([A-Z]*)(\d+)/.exec number
        unless cap
          result.push number
        else
          row1 = @gridLetters.indexOf cap[1]
          row2 = @gridLetters.indexOf cap[3]
          if row2 is '' then row2 = row1
          col1 = parseInt cap[2]
          col2 = parseInt cap[4]
          for row in [row1..row2]
            for col in [col1..col2]
              result.push @gridLetters[row] + col
      names = @parseMultiple name
      names.map((v) => @pinGroups[v] ?= [])
      if names.length > 1
        # Dearraying
        if names.length isnt result.length
          console.error 'Error: Pin count does not correspond pad count'
          process.exit 1
        for v, i in names
          @pins[result[i]] = @_pinObj result[i], v
          @pinGroups[v] = @pinGroups[v].concat result[i]
      else
        @pinGroups[name] = @pinGroups[name].concat result
        for number in result
          @pins[number] = @_pinObj number, name
    result

  #
  # Concatenate groups
  #
  _concatenateGroups: (groups) ->
    result = []
    groups = @parseMultiple groups
    for group in groups
      pinGroup = @pinGroups[group]
      if pinGroup? then result = result.concat pinGroup
    result

  #
  # Make dimensions more convenient
  #
  _convertDimensions: (housing) ->
    dimensions = [
      'bodyDiameter', 'bodyLength', 'bodyWidth', 'bodyHeight',
      'bossDiameter',
      'columnSpan',
      'height',
      'leadDiameter', 'leadHeight', 'leadLength', 'leadSpan', 'leadWidth',
      'leadDiameter1', 'leadHeight1', 'leadLength1', 'leadWidth1',
      'leadDiameter2', 'leadHeight2', 'leadLength2', 'leadWidth2',
      'pullBack',
      'rowSpan',
      'tabWidth', 'tabLength'
    ]

    for k, v of housing
      if typeof v is 'string' and (/^\d+(\.\d+)?-\d+(\.\d+)?$/.test v)
        v = v.replace(/\s+/g, '').split('-').map((v) -> parseFloat(v))
      if Array.isArray(v) and v.length > 0
        min = v[0]
        max = if v.length > 1 then v[1] else min
        nom = (max + min) / 2
        tol = max - min
        housing[k] = { min: min,  max: max,  nom: nom, tol: tol }
      else if dimensions.indexOf(k) isnt -1
        min = nom = max = v
        tol = 0
        housing[k] = { min: min,  max: max,  nom: nom, tol: tol }

    if housing.units is 'inches'
      @_inchToMm housing
      delete housing.units

  #
  # Return first valid handler
  #
  _firstHandler: (paths) ->
    for handlerPath in paths
      handlerError = null
      try
        handler = require handlerPath
      catch error
        handlerError = error
        if error.code is 'MODULE_NOT_FOUND' then continue else break
      break
    [handler, handlerError]

  #
  # Convert inches to millimeters
  #
  _inchToMm: (value) ->
    if typeof value is 'object'
      for k, v of value
        value[k] = @_inchToMm v
    else if @isFloat(value)
      value *= 25.4
      roundOff = 0.001
      value = Math.round(value / roundOff) * roundOff
    else if typeof value is 'string'
      if /([-0-9.]+\s*,?\s*)+/.test value
        value = value.replace(/\s+/g, '')
          .split(',')
          .map((v) => @_inchToMm(parseFloat v))
          .reduce((a, v) => a + ', ' + v)

    value

  #
  # Process obsolete parameter names
  #
  _legacy: (housing) ->
    convertations = [
      [/^drillDiameter(.*)/, 'holeDiameter$1']
    ]
    for k, v of housing
      for convertation in convertations
        if k.match convertation[0]
          k = k.replace convertation[0], convertation[1]
          housing[k] = v

  #
  # Add properties to pins
  #
  _parseProperties: () ->
    if @properties?
      props = ['analog', 'bidir', 'ground', 'in', 'inverted', 'nc', 'out', 'passive', 'power', 'z']
      for prop in props
        if @properties[prop]?
          groups = @parseMultiple @properties[prop]
          for group in groups
            @pinGroups[group]?.map((v) => @pins[v]?[prop] = true)

  #
  # Generate pin object
  #
  _pinObj: (number, name) ->
    obj = @pins[number]
    if obj?
      unless @library.symbol.shortPinNames then obj.name += '/' +  name
    else
      obj =
        name: name
        number: number

    obj

  #
  # Add dimensions from outline
  #
  _processOutline: (outline, subkeys, result = {}) ->
    unless outline? then return result
    sk = subkeys.shift() # TODO: Create copy of 'subkeys'
    for k, v of outline
      valueType = (typeof v is 'number') or (typeof v is 'string')
      if valueType
        unless result[k]? then result[k] = v
      else
        unless sk? then return
        re = new RegExp '^' + k + '$'
        if re.test(sk) then @_processOutline outline[k], subkeys, result
    result

module.exports = QedaElement
