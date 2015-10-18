fs = require 'fs'
mkdirp = require 'mkdirp'

#
# Generator of library in KiCad format
#
class KicadGenerator
  #
  # Constructor
  #
  constructor: (@library) ->

  #
  # Generate symbol library and footprint files
  #
  generate: (name) ->
    dir = './kikad'
    mkdirp.sync "#{dir}/#{name}.pretty"
    patterns = {}

    now = new Date
    timestamp = "#{now.getDate()}/#{now.getMonth() + 1}/#{now.getYear() + 1900} #{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}"
    fd = fs.openSync "#{dir}/#{name}.lib", 'w'
    fs.writeSync fd, "EESchema-LIBRARY Version 2.3 Date: #{timestamp}\n"
    fs.writeSync fd, '#encoding utf-8\n'
    for element in @library.elements
      @_generateSymbol fd, element
      for pattern in element.patterns
        patterns[pattern.name] = pattern
    fs.writeSync fd, '# End Library\n'
    fs.closeSync fd
    console.log "Generating KiCad library '#{name}.lib': OK"

    for patternName, pattern of patterns
      fd = fs.openSync "#{dir}/#{name}.pretty/#{patternName}.kicad_mod", 'w'
      @_generatePattern fd, pattern
      console.log "Generating KiCad footprint '#{patternName}.kicad_mod': OK"
      fs.closeSync fd

  #
  # Write pattern file
  #
  _generatePattern: (fd, pattern) ->
    fs.writeSync fd, "(module #{pattern.name} (layer F.Cu)\n"
    fs.writeSync fd, "  (attr smd)\n"
    for shape in pattern.shapes
      patObj = @_patternObj shape
      switch patObj.kind
        when 'pad' then fs.writeSync fd, "  (pad #{patObj.name} #{patObj.type} #{patObj.shape} (at #{patObj.x} #{patObj.y}) (size #{patObj.width} #{patObj.height}))\n"
      #console.log shape
    fs.writeSync fd, ")\n" # module

  #
  # Write symbol entry to library file
  #
  _generateSymbol: (fd, element) ->
    symbol = element.symbol
    symbol.invertVertical() # Positive vertical axis is pointing up in KiCad
    refObj = @_symbolObj symbol.attributes['refDes']
    nameObj = @_symbolObj symbol.attributes['name']
    fs.writeSync fd, "#\n# #{element.name}\n#\n"
    showPinNumbers = if element.schematics?.showPinNumbers then 'Y' else 'N'
    showPinNames = if element.schematics?.showPinNames then 'Y' else 'N'
    pinNameSpace = Math.round @library.symbol.pinNameSpace
    fs.writeSync fd, "DEF #{element.name} #{element.refDes} 0 #{pinNameSpace} #{showPinNumbers} #{showPinNames} 1 L N\n"
    fs.writeSync fd, "F0 \"#{element.refDes}\" #{refObj.x} #{refObj.y} #{refObj.size} H V #{refObj.halign} #{refObj.valign}NN\n"
    fs.writeSync fd, "F1 \"#{element.name}\" #{nameObj.x} #{nameObj.y} #{nameObj.size} H V #{nameObj.halign} #{nameObj.valign}NN\n"
    fs.writeSync fd, "DRAW\n"
    for shape in element.symbol.shapes
      symObj = @_symbolObj shape
      switch symObj.kind
        when 'pin' then fs.writeSync fd, "X #{symObj.name} #{symObj.number} #{symObj.x} #{symObj.y} #{symObj.length} #{symObj.orientation} #{symObj.sizeNum} #{symObj.sizeName} 1 1 #{symObj.type}#{symObj.shape}\n"
        when 'rectangle' then fs.writeSync fd, "S #{symObj.x} #{symObj.y} #{symObj.x + symObj.width} #{symObj.y + symObj.height} 1 1 0 #{symObj.fillStyle}\n"
    fs.writeSync fd, "ENDDRAW\n"
    fs.writeSync fd, "ENDDEF\n"

  #
  # Convert definition to pattern object
  #
  _patternObj: (shape) ->
    obj = shape
    if obj.shape is 'rectangle' then obj.shape = 'rect'
    obj

  #
  # Convert definition to symbol object
  #
  _symbolObj: (shape) ->
    obj = shape
    obj.x = Math.round obj.x
    obj.y = Math.round obj.y
    obj.length = Math.round obj.length
    if obj.halign?
      obj.halign = switch obj.halign
        when 'center' then 'C'
        when 'right' then 'R'
        else 'L'
    if obj.valign?
      obj.valign = switch obj.valign
        when 'center' then 'C'
        when 'bottom' then 'B'
        else 'T'
    if obj.orientation?
      obj.orientation = switch obj.orientation
        when 'left' then 'L'
        when 'up' then 'U'
        when 'down' then 'D'
        else 'R'
    obj.size = Math.round @library.symbol.textSize
    obj.sizeNum = Math.round @library.symbol.textSize
    obj.sizeName = Math.round @library.symbol.textSize

    obj.type = 'U'
    if obj.power or obj.ground
      obj.type = 'W' # Power input
      if obj.output then obj.type = 'w' # Power output
    else
      if obj.input and obj.output
        obj.type = 'B' # Bidirectional
      else if obj.input
        obj.type = 'I' # Input
      else
        obj.type = 'O' # Output
      if obj.z then obj.type = 'T' # Tristate

    obj.shape = ''
    if obj.invisible then obj.shape += 'N'
    if obj.inverted
      obj.shape += 'I'
    if obj.shape isnt '' then obj.shape = ' ' + obj.shape

    switch obj.fill
      when 'foreground' then obj.fillStyle = 'f'
      when 'backgroung' then obj.fillStyle = 'F'
      else obj.fillStyle = 'N'
    obj

module.exports = KicadGenerator
