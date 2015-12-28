fs = require 'fs'
mkdirp = require 'mkdirp'
sprintf = require('sprintf-js').sprintf

log = require './qeda-log'

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
  generate: (@name) ->
    dir = './kicad'
    mkdirp.sync "#{dir}/#{@name}.pretty"
    patterns = {}

    now = new Date
    timestamp = "#{now.getDate()}/#{now.getMonth() + 1}/#{now.getYear() + 1900} #{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}"
    log.start "KiCad library '#{@name}.lib'"
    fd = fs.openSync "#{dir}/#{@name}.lib", 'w'
    fs.writeSync fd, "EESchema-LIBRARY Version 2.3 Date: #{timestamp}\n"
    fs.writeSync fd, '#encoding utf-8\n'
    for element in @library.elements
      @_generateSymbol fd, element
      patterns[element.pattern.name] = element.pattern
    fs.writeSync fd, '# End Library\n'
    fs.closeSync fd
    log.ok()

    for patternName, pattern of patterns
      log.start "KiCad footprint '#{patternName}.kicad_mod'"
      fd = fs.openSync "#{dir}/#{@name}.pretty/#{patternName}.kicad_mod", 'w'
      @_generatePattern fd, pattern
      fs.closeSync fd
      log.ok()

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
            sprintf("  (fp_text %s %s (at #{@f} #{@f}%s) (layer %s)\n",
            patObj.name, patObj.text, patObj.x, patObj.y,
            if patObj.angle? then (' ' + patObj.angle.toString()) else ''
            patObj.layer)
          )
          fs.writeSync(fd,
            sprintf("    (effects (font (size #{@f} #{@f}) (thickness #{@f})))\n",
            patObj.fontSize, patObj.fontSize, patObj.lineWidth)
          )
          fs.writeSync fd, "  )\n"
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
            sprintf("  (pad %s %s %s (at #{@f} #{@f}) (size #{@f} #{@f}) (layers %s)"
            patObj.name, patObj.type, patObj.shape, patObj.x, patObj.y, patObj.width, patObj.height, patObj.layer)
          )
          if patObj.drill? then fs.writeSync fd, sprintf("\n    (drill #{@f})", patObj.drill)
          if patObj.mask? then fs.writeSync fd, sprintf("\n    (solder_mask_margin #{@f})", patObj.mask)
          if patObj.paste? then fs.writeSync fd, sprintf("\n    (solder_paste_margin #{@f})", patObj.paste)
          fs.writeSync fd, ")\n"

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
    fs.writeSync fd, "F1 \"#{element.name}\" #{nameObj.x} #{nameObj.y} #{nameObj.fontSize} #{nameObj.orientation} #{nameObj.visible} #{nameObj.halign} #{nameObj.valign}NN\n"
    fs.writeSync fd, "F2 \"#{@name}:#{element.pattern.name}\" 0 0 0 H I C CNN\n"
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
          when 'rectangle' then fs.writeSync fd, "S #{symObj.x1} #{symObj.y1} #{symObj.x2} #{symObj.y2} #{i} 1 #{symObj.lineWidth} #{symObj.fillStyle}\n"
          when 'line' then fs.writeSync fd, "P 2 #{i} 1 #{symObj.lineWidth} #{symObj.x1} #{symObj.y1} #{symObj.x2} #{symObj.y2} N\n"
      ++i
    fs.writeSync fd, "ENDDRAW\n"
    fs.writeSync fd, "ENDDEF\n"

  #
  # Convert definition to pattern object
  #
  _patternObj: (shape) ->
    obj = shape
    if obj.shape is 'rectangle' then obj.shape = 'rect'

    layers =
      topCopper: 'F.Cu'
      topMask: 'F.Mask'
      topPaste: 'F.Paste'
      topSilkscreen: 'F.SilkS'
      topAssembly: 'F.Fab'
      topCourtyard: 'F.CrtYd'
      intCopper: '*.Cu'
      bottomCopper: 'B.Cu'
      bottomMask: 'B.Mask'
      bottomPaste: 'B.Paste'
      bottomSilkscreen: 'B.SilkS'
      bottomAssembly: 'B.Fab'
      bottomCourtyard: 'B.CrtYd'
    obj.layer = obj.layer.map((a) => layers[a]).join(' ')

    if obj.mask? and (obj.mask < 0.001) then obj.mask = 0.001 # KiCad does not support zero value
    if obj.paste? and (obj.paste > -0.001) then obj.paste = -0.001 # KiCad does not support zero value

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
    else if obj.kind is 'pad'
      if obj.type is 'mount' then obj.shape ?= 'circle'
      obj.width ?= obj.drill ? obj.size
      obj.height ?= obj.drill ? obj.size

      types =
        smd: 'smd'
        th: 'thru_hole'
        mount: 'np_thru_hole'
      obj.type = types[obj.type]

    obj

  #
  # Convert definition to symbol object
  #
  _symbolObj: (shape) ->
    unless shape? then return
    obj = shape
    obj.name ?= '~'
    if obj.name is '' then obj.name = '~'

    obj.visible ?= true
    obj.visible = if obj.visible then 'V' else 'I'
  
    props = ['x', 'y', 'length', 'lineWidth']
    for prop in props
      if obj[prop]? then obj[prop] = Math.round obj[prop]

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
      if obj.bidir or (obj.in and obj.out)
        obj.type = 'B' # Bidirectional
      else if obj.in
        obj.type = 'I' # Input
      else if obj.out
        obj.type = 'O' # Output
      else if obj.nc
        obj.type = 'N' # Not connected
      else if obj.z
        obj.type = 'T' # Tristate
      else
        obj.type = 'U' # Unspecified

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
