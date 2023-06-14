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
    mkdirp.sync "#{dir}/#{@name}.3dshapes"

    if @library.nodate
      timestamp = "00/00/0000 00:00:00"
    else
      now = new Date
      timestamp = sprintf "%02d/%02d/%d %02d:%02d:%02d",
        now.getDate(), now.getMonth() + 1, now.getYear() + 1900,
        now.getHours(), now.getMinutes(), now.getSeconds()
    log.start "KiCad library '#{@name}.lib'"
    fd = fs.openSync "#{dir}/#{@name}.lib", 'w'
    fs.writeSync fd, "EESchema-LIBRARY Version 2.3 Date: #{timestamp}\n"
    fs.writeSync fd, '#encoding utf-8\n'
    patterns = {}

    # Symbols
    for element in @library.elements
      @_generateSymbol fd, element
      if element.pattern? then patterns[element.pattern.name] = element.pattern
    fs.writeSync fd, '# End Library\n'
    fs.closeSync fd
    log.ok()

    # Doc
    log.start "KiCad library doc '#{@name}.dcm'"
    fd = fs.openSync "#{dir}/#{@name}.dcm", 'w'
    fs.writeSync fd, "EESchema-DOCLIB  Version 2.0 Date: #{timestamp}\n#\n"
    for element in @library.elements
      @_generateDoc fd, element
    fs.writeSync fd, '# End Doc Library\n'
    fs.closeSync fd
    log.ok()

    # Footprints
    for patternName, pattern of patterns
      log.start "KiCad footprint '#{patternName}.kicad_mod'"
      fd = fs.openSync "#{dir}/#{@name}.pretty/#{patternName}.kicad_mod", 'w'
      @_generatePattern fd, pattern
      fs.closeSync fd
      log.ok()

    # 3D shapes
    for patternName, pattern of patterns
      log.start "KiCad 3D shape '#{patternName}.wrl'"
      fd = fs.openSync "#{dir}/#{@name}.3dshapes/#{patternName}.wrl", 'w'
      @_generateVrml fd, pattern
      fs.closeSync fd
      log.ok()

  #
  # Write doc entry to library doc file
  #
  _generateDoc: (fd, element) ->
    fields = ['description', 'keywords', 'datasheet']
    keys = ['D', 'K', 'F']
    empty = true
    for field in fields
      if element[field]?
        empty = false
        break
    if empty then return
    fs.writeSync fd, "$CMP #{element.name}\n"
    for i in [0..(fields.length - 1)]
      if element[fields[i]]? then fs.writeSync fd, "#{keys[i]} #{element[fields[i]]}\n"
    fs.writeSync fd, '$ENDCMP\n#\n'

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
            sprintf("  (fp_text %s %s (at #{@f} #{@f}%s)%s (layer %s)\n",
              patObj.name, patObj.text, patObj.x, patObj.y,
              if patObj.angle? then (' ' + patObj.angle.toString()) else '',
              unless patObj.visible then ' hide' else '',
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
          if patObj.shape is 'rect' and @library.pattern.smoothPadCorners
            cornerRadius = Math.min(patObj.width, patObj.height) * @library.pattern.ratio.cornerToWidth
            if cornerRadius > @library.pattern.maximum.cornerRadius then cornerRadius = @library.pattern.maximum.cornerRadius
            if cornerRadius > 0 then patObj.shape = 'roundrect'

          fs.writeSync(fd,
            sprintf("  (pad %s %s %s (at #{@f} #{@f}) (size #{@f} #{@f}) (layers %s)"
              patObj.name, patObj.type, patObj.shape, patObj.x, patObj.y, patObj.width, patObj.height, patObj.layer)
          )
          if patObj.slotWidth? and patObj.slotHeight?
            fs.writeSync fd, sprintf("\n    (drill oval #{@f} #{@f})", patObj.slotWidth, patObj.slotHeight)
          else if patObj.hole?
            fs.writeSync fd, sprintf("\n    (drill #{@f})", patObj.hole)
          if patObj.mask? then fs.writeSync fd, sprintf("\n    (solder_mask_margin #{@f})", patObj.mask)
          if patObj.paste? then fs.writeSync fd, sprintf("\n    (solder_paste_margin #{@f})", patObj.paste)

          if patObj.shape is 'roundrect'
            ratio = cornerRadius / Math.min(patObj.width, patObj.height)
            fs.writeSync fd, sprintf("\n    (roundrect_rratio #{@f})", ratio)
          fs.writeSync fd, ")\n"

    fs.writeSync fd, "  (model #{pattern.name}.wrl\n"
    fs.writeSync fd, "    (at (xyz 0 0 0))\n"
    fs.writeSync fd, "    (scale (xyz 1 1 1))\n"
    fs.writeSync fd, "    (rotate (xyz 0 0 0 ))\n"
    fs.writeSync fd, "  )\n" # model

    fs.writeSync fd, ")\n" # module

  #
  # Format pin names for KiCad
  #
  _formatPinName: (name) ->
    formatted = name.replace /~{([^}]+)}/g, '~$1~'
    if (formatted.match(/~/g) || []).length % 2 == 1
      formatted += '~'
    return formatted

  #
  # Write symbol entry to library file
  #
  _generateSymbol: (fd, element) ->
    for symbol in element.symbols
      symbol.resize 50, true # Resize to grid 50 mil with rounding
      symbol.invertVertical() # Positive vertical axis is pointing up in KiCad

    symbol = element.symbols[0]
    refObj = @_symbolObj symbol.attributes['refDes']
    nameObj = @_symbolObj symbol.attributes['name']
    fs.writeSync fd, "#\n# #{element.name}\n#\n"
    showPinNumbers = if element.schematic?.showPinNumbers then 'Y' else 'N'
    showPinNames = if element.schematic?.showPinNames then 'Y' else 'N'

    pinNameSpace = 0
    for shape in symbol.shapes
      if shape.kind is 'pin'
        pinNameSpace = Math.round shape.space
        break

    patternName = ''
    if element.pattern? then patternName = "#{@name}:#{element.pattern.name}"

    powerSymbol = 'N'
    if element.power then powerSymbol = 'P'

    fs.writeSync fd, "DEF #{element.name} #{element.refDes} 0 #{pinNameSpace} #{showPinNumbers} #{showPinNames} #{element.symbols.length} L #{powerSymbol}\n"
    fs.writeSync fd, "F0 \"#{element.refDes}\" #{refObj.x} #{refObj.y} #{refObj.fontSize} #{refObj.orientation} #{refObj.visible} #{refObj.halign} #{refObj.valign}NN\n"
    fs.writeSync fd, "F1 \"#{element.name}\" #{nameObj.x} #{nameObj.y} #{nameObj.fontSize} #{nameObj.orientation} #{nameObj.visible} #{nameObj.halign} #{nameObj.valign}NN\n"
    fs.writeSync fd, "F2 \"#{patternName}\" 0 0 0 H I C CNN\n"
    if element.datasheet?
      fs.writeSync fd, "F3 \"#{element.datasheet}\" 0 0 0 H I C CNN\n"
    i = 0
    for shape in symbol.shapes
      if (shape.kind is 'attribute') and (shape.name isnt 'refDes') and (shape.name isnt 'name')
        attrObj = @_symbolObj shape
        fs.writeSync fd, "F#{4 + i} \"#{attrObj.text}\" #{attrObj.x} #{attrObj.y} #{attrObj.fontSize} #{attrObj.orientation} V #{attrObj.halign} #{attrObj.valign}NN \"#{attrObj.name}\"\n"
        ++i

    if element.aliases? and element.aliases.length then fs.writeSync fd, "ALIAS #{element.aliases.join(' ')}\n"
    if element.pattern?
      fs.writeSync fd, "$FPLIST\n"
      fs.writeSync fd, "  #{element.pattern.name}\n"
      fs.writeSync fd, "$ENDFPLIST\n"
    fs.writeSync fd, "DRAW\n"
    i = 1
    for symbol in element.symbols
      for shape in symbol.shapes
        symObj = @_symbolObj shape
        switch symObj.kind
          when 'pin' then fs.writeSync fd, "X #{@_formatPinName(symObj.name)} #{symObj.number} #{symObj.x} #{symObj.y} #{symObj.length} #{symObj.orientation} #{symObj.fontSize} #{symObj.fontSize} #{i} 1 #{symObj.type}#{symObj.shape}\n"
          when 'rectangle' then fs.writeSync fd, "S #{symObj.x1} #{symObj.y1} #{symObj.x2} #{symObj.y2} #{i} 1 #{symObj.lineWidth} #{symObj.fillStyle}\n"
          when 'line' then fs.writeSync fd, "P 2 #{i} 1 #{symObj.lineWidth} #{symObj.x1} #{symObj.y1} #{symObj.x2} #{symObj.y2} N\n"
          when 'circle' then fs.writeSync fd, "C #{symObj.x} #{symObj.y} #{symObj.radius} #{i} 1 #{symObj.lineWidth} #{symObj.fillStyle}\n"
          when 'arc'
            symObj.start = Math.round symObj.start*10
            symObj.end = Math.round symObj.end*10
            fs.writeSync fd, "A #{symObj.x} #{symObj.y} #{symObj.radius} #{symObj.start} #{symObj.end} #{i} 1 #{symObj.lineWidth} #{symObj.fillStyle}\n"
          when 'poly'
            pointCount = symObj.points.length / 2
            polyPoints = symObj.points.reduce((p, v) -> p + ' ' + v)
            fs.writeSync fd, "P #{pointCount} #{i} 1 #{symObj.lineWidth} #{polyPoints} #{symObj.fillStyle}\n"
          when 'text'
            hidden = if symObj.visible is 'I' then 1 else 0
            fs.writeSync fd, "T #{symObj.angle} #{symObj.x} #{symObj.y} #{symObj.fontSize} #{hidden} #{i} 1 \"#{symObj.text}\" #{symObj.italic} #{symObj.bold} #{symObj.halign} #{symObj.valign}\n"
      ++i
    fs.writeSync fd, "ENDDRAW\n"
    fs.writeSync fd, "ENDDEF\n"

  #
  # Write 3D shape file in VRML format
  #
  _generateVrml: (fd, pattern) ->
    xpos = pattern.box.x/2.54
    ypos = pattern.box.y/2.54
    zpos = pattern.box.height/2/2.54
    width = pattern.box.width/2.54
    length = pattern.box.length/2.54
    height = pattern.box.height/2.54

    fs.writeSync fd, "#VRML V2.0 utf8\n"
    fs.writeSync fd, "Transform {\n"
    fs.writeSync fd, "  translation #{xpos} #{ypos} #{zpos}\n"
    fs.writeSync fd, "  children [\n"
    fs.writeSync fd, "    Shape {\n"
    fs.writeSync fd, "      geometry Box {size #{width} #{length} #{height}}\n"
    fs.writeSync fd, "      appearance Appearance {\n"
    fs.writeSync fd, "        material Material {\n"
    fs.writeSync fd, "          diffuseColor 0.37 0.37 0.37\n"
    fs.writeSync fd, "          emissiveColor 0.0 0.0 0.0\n"
    fs.writeSync fd, "          specularColor 1.0 1.0 1.0\n"
    fs.writeSync fd, "          ambientIntensity 1.0\n"
    fs.writeSync fd, "          transparency 0.5\n"
    fs.writeSync fd, "          shininess 1.0\n"
    fs.writeSync fd, "        }\n" # Material
    fs.writeSync fd, "      }\n" # Appearance
    fs.writeSync fd, "    }\n" # Shape
    fs.writeSync fd, "  ]\n" # children
    fs.writeSync fd, "}\n" # Transform

  #
  # Convert definition to pattern object
  #
  _patternObj: (shape) ->
    obj = shape
    obj.visible ?= true
    if obj.shape is 'rectangle' then obj.shape = 'rect'
    if obj.shape is 'circle' and obj.width != obj.height then obj.shape = 'oval'

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
    obj.layer = obj.layer.map((v) => layers[v]).join(' ')

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
      obj.width ?= obj.hole ? obj.size
      obj.height ?= obj.hole ? obj.size

      types =
        'smd': 'smd'
        'through-hole': 'thru_hole'
        'mounting-hole': 'np_thru_hole'
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

    obj.fontSize = Math.round(obj.fontSize)
    obj.italic = if obj.italic then 'Italic' else 'Normal'
    obj.bold = if obj.bold then 1 else 0

    obj.type = 'U'
    if obj.power or obj.ground
      obj.type = 'W' # Power input
      if obj.out then obj.type = 'w' # Power output
    else
      if obj.bidir or (obj.in and obj.out)
        obj.type = 'B' # Bidirectional
      else if obj.in
        obj.type = 'I' # Input
      else if obj.out
        obj.type = 'O' # Output
      else if obj.passive
        obj.type = 'P' # Passive
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
      when 'background' then obj.fillStyle = 'F'
      else obj.fillStyle = 'N'
    obj

module.exports = KicadGenerator
