fs = require 'fs'
mkdirp = require 'mkdirp'
sprintf = require('sprintf-js').sprintf

#
# Generator of library in KiCad format
#
class KicadGenerator
  #
  # Constructor
  #
  constructor: (@library) ->
    @f = "%.#{@library.pattern.decimals}f"
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
      patterns[element.pattern.name] = element.pattern
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
    if pattern.type is 'smd' then fs.writeSync fd, "  (attr smd)\n"
    for shape in pattern.shapes
      patObj = @_patternObj shape
      switch patObj.kind
        when 'attribute'
          fs.writeSync(fd,
            sprintf("  (fp_text %s %s (at #{@f} #{@f}) (layer %s)\n",
            patObj.name, patObj.text, patObj.x, patObj.y, patObj.layer)
          )
          fs.writeSync(fd,
            sprintf("    (effects (font (size #{@f} #{@f}) (thickness #{@f})))\n",
            patObj.fontSize, patObj.fontSize, patObj.lineWidth)
          )
          fs.writeSync fd, "  )"
        when 'circle'
          fs.writeSync(fd,
            sprintf("  (fp_circle (center #{@f} #{@f}) (end #{@f} #{@f}) (layer %s) (width #{@f}))\n",
            patObj.x, patObj.y, patObj.x, patObj.y + patObj.radius, patObj.layer, patObj.lineWidth)
          )
        when 'line'
          fs.writeSync(fd,
            sprintf("  (fp_line (start #{@f} #{@f}) (end #{@f} #{@f}) (layer %s) (width #{@f}))\n"
            patObj.x1, patObj.y1, patObj.x2, patObj.y2, patObj.layer, patObj.lineWidth)
          )
        when 'pad'
          fs.writeSync(fd,
            sprintf("  (pad %s %s %s (at #{@f} #{@f}) (size #{@f} #{@f}) (layers %s))\n"
            patObj.name, patObj.type, patObj.shape, patObj.x, patObj.y, patObj.width, patObj.height, patObj.layer)
          )
    fs.writeSync fd, ")\n" # module

  #
  # Write symbol entry to library file
  #
  _generateSymbol: (fd, element) ->
    for symbol in element.symbols
      symbol.invertVertical() # Positive vertical axis is pointing up in KiCad
    symbol = element.symbols[0]
    refObj = @_symbolObj symbol.attributes['refDes']
    nameObj = @_symbolObj symbol.attributes['name']
    fs.writeSync fd, "#\n# #{element.name}\n#\n"
    showPinNumbers = if element.schematic?.showPinNumbers then 'Y' else 'N'
    showPinNames = if element.schematic?.showPinNames then 'Y' else 'N'
    pinNameSpace = Math.round @library.symbol.space.pinName
    fs.writeSync fd, "DEF #{element.name} #{element.refDes} 0 #{pinNameSpace} #{showPinNumbers} #{showPinNames} #{element.symbols.length} L N\n"
    fs.writeSync fd, "F0 \"#{element.refDes}\" #{refObj.x} #{refObj.y} #{refObj.fontSize} #{refObj.orientation} V #{refObj.halign} #{refObj.valign}NN\n"
    fs.writeSync fd, "F1 \"#{element.name}\" #{nameObj.x} #{nameObj.y} #{nameObj.fontSize} #{nameObj.orientation} V #{nameObj.halign} #{nameObj.valign}NN\n"
    if symbol.attributes['user']?
      attrObj = @_symbolObj symbol.attributes['user']
      fs.writeSync fd, "F4 \"#{attrObj.text}\" #{attrObj.x} #{attrObj.y} #{attrObj.fontSize} #{attrObj.orientation} V #{attrObj.halign} #{attrObj.valign}NN\n"

    if element.aliases? then fs.writeSync fd, "ALIAS #{element.aliases.join(' ')}\n"
    fs.writeSync fd, "$FPLIST\n"
    fs.writeSync fd, "  #{element.pattern.name}\n"
    fs.writeSync fd, "$ENDFPLIST\n"
    fs.writeSync fd, "DRAW\n"
    i = 1
    for symbol in element.symbols
      for shape in symbol.shapes
        symObj = @_symbolObj shape
        switch symObj.kind
          when 'pin' then fs.writeSync fd, "X #{symObj.name} #{symObj.number} #{symObj.x} #{symObj.y} #{symObj.length} #{symObj.orientation} #{symObj.fontSizeNum} #{symObj.fontSizeName} #{i} 1 #{symObj.type}#{symObj.shape}\n"
          when 'rectangle' then fs.writeSync fd, "S #{symObj.x} #{symObj.y} #{symObj.x + symObj.width} #{symObj.y + symObj.height} #{i} 1 0 #{symObj.fillStyle}\n"
      ++i
    fs.writeSync fd, "ENDDRAW\n"
    fs.writeSync fd, "ENDDEF\n"

  #
  # Convert definition to pattern object
  #
  _patternObj: (shape) ->
    obj = shape
    if obj.shape is 'rectangle' then obj.shape = 'rect'
    obj.layer = switch obj.layer
      when 'top'
        if obj.kind is 'pad' then 'F.Cu F.Paste F.Mask' else 'F.Cu'
      when 'topSilkscreen' then 'F.SilkS'
      when 'topAssembly' then 'F.Fab'
      when 'bottom'
        if obj.kind is 'pad' then 'B.Cu B.Paste B.Mask' else 'B.Cu'
      when 'bottomSilkscreen' then 'B.SilkS'
      when 'bottomAssembly' then 'B.Fab'
      else 'F.Cu'
    if obj.kind is 'attribute'
      switch obj.name
        when 'refDes'
          obj.name = 'reference'
          obj.text = 'REF**'
          obj.fontSize ?= @library.pattern.fontSize.refDes
        when 'value'
          obj.fontSize ?= @library.pattern.fontSize.value
        else
          obj.name = 'user'
          obj.fontSize ?= @library.pattern.fontSize.default
    obj

  #
  # Convert definition to symbol object
  #
  _symbolObj: (shape) ->
    obj = shape
    obj.x = Math.round obj.x
    obj.y = Math.round obj.y
    obj.length = Math.round obj.length
    obj.halign = switch obj.halign
      when 'center' then 'C'
      when 'right' then 'R'
      else 'L'
    obj.valign = switch obj.valign
      when 'center' then 'C'
      when 'bottom' then 'B'
      else 'T'
    obj.orientation = switch obj.orientation
      when 'left' then 'L'
      when 'right' then 'R'
      when 'up' then 'U'
      when 'down' then 'D'
      when 'horizontal' then 'H'
      when 'vertical' then 'V'
      else 'H'
    obj.fontSize = Math.round(if @library.symbol.fontSize[shape.name]? then @library.symbol.fontSize[shape.name] else @library.symbol.fontSize.default)
    obj.fontSizeNum = Math.round @library.symbol.fontSize.pinNumber
    obj.fontSizeName = Math.round @library.symbol.fontSize.pinName

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
