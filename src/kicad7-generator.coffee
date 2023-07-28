fs = require 'fs'
mkdirp = require 'mkdirp'
sprintf = require('sprintf-js').sprintf

log = require './qeda-log'

#
# Generator of library in KiCad 7 format
#
class Kicad7Generator
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

    # Symbols
    # https://dev-docs.kicad.org/en/file-formats/sexpr-symbol-lib/
    log.start "KiCad symbol library '#{@name}.kicad_sym'"
    fd = fs.openSync "#{dir}/#{@name}.kicad_sym", 'w'
    fs.writeSync fd, "(kicad_symbol_lib (version 20220914) (generator qeda)\n" # KiCAD 7.1.0 timestamp
    patterns = {}
    for element in @library.elements
      @_generateSymbol fd, element
      if element.pattern?
        patterns[element.pattern.name] = element.pattern
        if element.housing.model? and element.housing.model.file?
          element.pattern.model = element.housing.model
          element.pattern.model.extension = element.pattern.model.file.split('.').pop()
          if element.pattern.model.position? then element.pattern.model.position = element.pattern.model.position.replaceAll(' ','').split(',')
          if element.pattern.model.rotation? then element.pattern.model.rotation = element.pattern.model.rotation.replaceAll(' ','').split(',')
          if element.pattern.model.scale? then element.pattern.model.scale = element.pattern.model.scale.replaceAll(' ','').split(',')
    fs.writeSync fd, ")\n"
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
      if pattern.model?
        log.start "KiCad 3D shape '#{patternName}.#{pattern.model.extension}'"
        fs.copyFileSync "./#{pattern.model.file}", "#{dir}/#{@name}.3dshapes/#{patternName}.#{pattern.model.extension}"
      else
        log.start "KiCad 3D shape '#{patternName}.wrl'"
        fd = fs.openSync "#{dir}/#{@name}.3dshapes/#{patternName}.wrl", 'w'
        @_generateVrml fd, pattern
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

    if pattern.model?
      fs.writeSync fd, "  (model ../#{@name}.3dshapes/#{pattern.name}.#{pattern.model.extension}\n"
      if pattern.model.position? and pattern.model.position.length == 3
        fs.writeSync fd, "    (at (xyz #{pattern.model.position.map((a) => a/25.4).join(' ')}))\n"
      else
        fs.writeSync fd, "    (at (xyz 0 0 0))\n"
      if pattern.model.scale? and pattern.model.scale.length == 3
        fs.writeSync fd, "    (scale (xyz #{pattern.model.scale.join(' ')}))\n"
      else
        fs.writeSync fd, "    (scale (xyz 1 1 1))\n"
      if pattern.model.rotation? and pattern.model.rotation.length == 3
        fs.writeSync fd, "    (rotate (xyz #{pattern.model.rotation.join(' ')}))\n"
      else
        fs.writeSync fd, "    (rotate (xyz 0 0 0))\n"
    else
      fs.writeSync fd, "  (model ../#{@name}.3dshapes/#{pattern.name}.wrl\n"
      fs.writeSync fd, "    (at (xyz 0 0 0))\n"
      fs.writeSync fd, "    (scale (xyz 0.3937 0.3937 0.3937))\n"
      fs.writeSync fd, "    (rotate (xyz 0 0 0 ))\n"
    fs.writeSync fd, "  )\n" # model

    fs.writeSync fd, ")\n" # module

  #
  # Format pin names for KiCad 7
  #
  _formatPinName: (name) ->
    formatted = name.replace /~([^~{}]+)~/g, '~{$1}'
    formatted = formatted.replace /~([^~{}]+)/g, '~{$1}'
    return formatted

  #
  # Write symbol file
  #
  _generateSymbol: (fd, element) ->
    for symbol in element.symbols
      symbol.resize 50 * 0.0254, false # Resize to grid 50 mil, in mm
      symbol.invertVertical() # Positive vertical axis is pointing up in KiCad

    # Write symbol name
    fs.writeSync fd, "  (symbol \"#{element.name}\""
    if element.power == true
      fs.writeSync fd, " (power)"
    if element.schematic?.showPinNumbers == false
      fs.writeSync fd, " (pin_numbers hide)"
    if element.schematic?.showPinNames == false
      fs.writeSync fd, " (pin_names hide)"
    if element.power == true
      fs.writeSync fd, " (in_bom no) (on_board no)\n"
    else
      fs.writeSync fd, " (in_bom yes) (on_board yes)\n"

    symbol = element.symbols[0]
    refObj = @_symbolObj symbol.attributes['refDes']
    nameObj = @_symbolObj symbol.attributes['name']

    # Write symbol properties
    propId = 0
    fs.writeSync fd, "    (property \"Reference\" \"#{element.refDes}\""
    fs.writeSync fd, sprintf(" (at #{@f} #{@f} #{refObj.orientation})\n", refObj.x, refObj.y)
    fs.writeSync fd, "      (effects (font (size #{refObj.fontSize} #{refObj.fontSize})"
    if refObj.bold then fs.writeSync fd, " bold"
    if refObj.italic then fs.writeSync fd, " italic"
    fs.writeSync fd, ")"
    if refObj.halign == 'left' or refObj.halign == 'right' or refObj.valign == 'top' or refObj.valign == 'bottom'
      fs.writeSync fd, " (justify"
      if refObj.halign == 'left' or refObj.halign == 'right'
        fs.writeSync fd, " #{refObj.halign}"
      if refObj.valign == 'top' or refObj.valign == 'bottom'
        fs.writeSync fd, " #{refObj.valign}"
      fs.writeSync fd, ")"
    if !refObj.visible
      fs.writeSync fd, " hide"
    fs.writeSync fd, ")\n"
    fs.writeSync fd, "    )\n"
    
    if element.value?
      fs.writeSync fd, sprintf("    (property \"Value\" \"#{element.value}\" (at #{@f} #{@f} #{nameObj.orientation})\n", nameObj.x, nameObj.y)
    else
      fs.writeSync fd, sprintf("    (property \"Value\" \"#{element.name}\" (at #{@f} #{@f} #{nameObj.orientation})\n", nameObj.x, nameObj.y)
    fs.writeSync fd, "      (effects (font (size #{nameObj.fontSize} #{nameObj.fontSize})"
    if nameObj.bold then fs.writeSync fd, " bold"
    if nameObj.italic then fs.writeSync fd, " italic"
    fs.writeSync fd, ")"
    if nameObj.halign == 'left' or nameObj.halign == 'right' or nameObj.valign == 'top' or nameObj.valign == 'bottom'
      fs.writeSync fd, " (justify"
      if nameObj.halign == 'left' or nameObj.halign == 'right'
        fs.writeSync fd, " #{nameObj.halign}"
      if nameObj.valign == 'top' or nameObj.valign == 'bottom'
        fs.writeSync fd, " #{nameObj.valign}"
      fs.writeSync fd, ")"
    if !nameObj.visible
      fs.writeSync fd, " hide"
    fs.writeSync fd, ")\n"
    fs.writeSync fd, "    )\n"

    fs.writeSync fd, "    (property \"Footprint\" \""
    if element.pattern?
      patternName = "#{@name}:#{element.pattern.name}"
      fs.writeSync fd, "#{patternName}"
    fs.writeSync fd, "\" (at 0 0 0)\n"
    fs.writeSync fd, "      (effects (font (size #{nameObj.fontSize} #{nameObj.fontSize})) hide)\n"
    fs.writeSync fd, "    )\n"

    fs.writeSync fd, "    (property \"Datasheet\" \""
    if element.datasheet?
      fs.writeSync fd, "#{element.datasheet}"
    else
      fs.writeSync fd, "~"
    fs.writeSync fd, "\" (at 0 0 0)\n"
    fs.writeSync fd, "      (effects (font (size #{nameObj.fontSize} #{nameObj.fontSize})) hide)\n"
    fs.writeSync fd, "    )\n"

    if element.description?
      fs.writeSync fd, "    (property \"ki_description\" \"#{element.description}\" (at 0 0 0)\n"
      fs.writeSync fd, "      (effects (font (size #{nameObj.fontSize} #{nameObj.fontSize})) hide)\n"
      fs.writeSync fd, "    )\n"

    if element.keywords?
      fs.writeSync fd, "    (property \"ki_keywords\" \"#{element.keywords}\" (at 0 0 0)\n"
      fs.writeSync fd, "      (effects (font (size #{nameObj.fontSize} #{nameObj.fontSize})) hide)\n"
      fs.writeSync fd, "    )\n"

    if element.value?
      fs.writeSync fd, "    (property \"Part#\" \"#{element.name}\" (at 0 0 0)\n"
      fs.writeSync fd, "      (effects (font (size #{nameObj.fontSize} #{nameObj.fontSize})) hide)\n"
      fs.writeSync fd, "    )\n"

    for symbol, index in element.symbols
      # draw graphic items
      fs.writeSync fd, "    (symbol \"#{element.name}_#{index+1}_1\"\n"
      for shape in symbol.shapes
        symObj = @_symbolObj shape
        switch symObj.kind
          when 'rectangle'
            fs.writeSync fd, sprintf("      (rectangle (start #{@f} #{@f}) (end #{@f} #{@f})\n", symObj.x1, symObj.y1, symObj.x2, symObj.y2)
            fs.writeSync fd, sprintf("        (stroke (width #{@f}) (type default))\n", symObj.lineWidth)
            fs.writeSync fd, "        (fill (type #{symObj.fillStyle}))\n"
            fs.writeSync fd, "      )\n"
          when 'line'
            fs.writeSync fd, "      (polyline\n"
            fs.writeSync fd, "        (pts\n"
            fs.writeSync fd, sprintf("          (xy #{@f} #{@f})\n", symObj.x1, symObj.y1)
            fs.writeSync fd, sprintf("          (xy #{@f} #{@f})\n", symObj.x2, symObj.y2)
            fs.writeSync fd, "        )\n"
            fs.writeSync fd, sprintf("        (stroke (width #{@f}) (type default))\n", symObj.lineWidth)
            fs.writeSync fd, "        (fill (type #{symObj.fillStyle}))\n"
            fs.writeSync fd, "      )\n"
          when 'circle'
            fs.writeSync fd, sprintf("      (circle (center #{@f} #{@f}) (radius #{@f})\n" ,symObj.x, symObj.y, symObj.radius)
            fs.writeSync fd, sprintf("        (stroke (width #{@f}) (type default))\n", symObj.lineWidth)
            fs.writeSync fd, "        (fill (type #{symObj.fillStyle}))\n"
            fs.writeSync fd, "      )\n"
          when 'arc'
            fs.writeSync fd, "      (arc"
            fs.writeSync fd, sprintf(" (start #{@f} #{@f})", symObj.x + Math.cos(symObj.start * Math.PI / 180) * symObj.radius, symObj.y + Math.sin(symObj.start * Math.PI / 180) * symObj.radius)
            fs.writeSync fd, sprintf(" (mid #{@f} #{@f})", symObj.x + Math.cos((symObj.start + symObj.end) / 2 * Math.PI / 180) * symObj.radius, symObj.y + Math.sin((symObj.start + symObj.end) / 2 * Math.PI / 180)* symObj.radius)
            fs.writeSync fd, sprintf(" (end #{@f} #{@f})\n", symObj.x + Math.cos(symObj.end * Math.PI / 180) * symObj.radius, symObj.y + Math.sin(symObj.end * Math.PI / 180) * symObj.radius)
            fs.writeSync fd, sprintf("        (stroke (width #{@f}) (type default))\n", symObj.lineWidth)
            fs.writeSync fd, "        (fill (type #{symObj.fillStyle}))\n"
            fs.writeSync fd, "      )\n"
          when 'poly'
            polyPoints = ""
            for i in [0..(symObj.points.length / 2 - 1)]
              polyPoints += sprintf(" (xy #{@f} #{@f})", symObj.points[i * 2 + 0], symObj.points[i * 2 + 1])
            fs.writeSync fd, "      (polyline\n"
            fs.writeSync fd, "        (pts#{polyPoints})\n"
            fs.writeSync fd, sprintf("        (stroke (width #{@f}) (type default))\n", symObj.lineWidth)
            fs.writeSync fd, "        (fill (type #{symObj.fillStyle}))\n"
            fs.writeSync fd, "      )\n"
          when 'text'
            fs.writeSync fd, "      (text \"#{symObj.text}\"\n"
            fs.writeSync fd, sprintf("        (at #{@f} #{@f} #{nameObj.orientation * 10})\n", symObj.x, symObj.y)
            fs.writeSync fd, "        (effects (font (size #{symObj.fontSize} #{symObj.fontSize})"
            if symObj.bold then fs.writeSync fd, " bold"
            if symObj.italic then fs.writeSync fd, " italic"
            fs.writeSync fd, ")"
            if symObj.halign == 'left' or symObj.halign == 'right' or symObj.valign == 'top' or symObj.valign == 'bottom'
              fs.writeSync fd, " (justify"
              if symObj.halign == 'left' or symObj.halign == 'right'
                fs.writeSync fd, " #{symObj.halign}"
              if symObj.valign == 'top' or symObj.valign == 'bottom'
                fs.writeSync fd, " #{symObj.valign}"
              fs.writeSync fd, ")"
            if !symObj.visible
              fs.writeSync fd, " hide"
            fs.writeSync fd, ")\n"
            fs.writeSync fd, "      )\n"
      # draw pins
      for shape in symbol.shapes
        symObj = @_symbolObj shape
        switch symObj.kind
          when 'pin'
            fs.writeSync fd, "      (pin #{symObj.type} "
            if symObj.invisible && symbol.power == false
              fs.writeSync fd, "non_logic"
            else if symObj.inverted
              fs.writeSync fd, "inverted"
            else
              fs.writeSync fd, "line"
            fs.writeSync fd, sprintf(" (at #{@f} #{@f} #{symObj.orientation})", symObj.x, symObj.y)
            fs.writeSync fd, sprintf(" (length #{@f})\n", symObj.length)
            fs.writeSync fd, "        (name \"#{@_formatPinName(symObj.name)}\" (effects (font (size #{symObj.fontSize} #{symObj.fontSize})"
            if symObj.bold then fs.writeSync fd, " bold"
            if symObj.italic then fs.writeSync fd, " italic"
            fs.writeSync fd, ")"
            if symObj.halign == 'left' or symObj.halign == 'right' or symObj.valign == 'top' or symObj.valign == 'bottom'
              fs.writeSync fd, " (justify"
              if symObj.halign == 'left' or symObj.halign == 'right'
                fs.writeSync fd, " #{symObj.halign}"
              if symObj.valign == 'top' or symObj.valign == 'bottom'
                fs.writeSync fd, " #{symObj.valign}"
              fs.writeSync fd, ")"
            fs.writeSync fd, "))\n"
            fs.writeSync fd, "        (number \"#{symObj.number}\" (effects (font (size #{symObj.fontSize} #{symObj.fontSize}))))\n"
            fs.writeSync fd, "      )\n"
      fs.writeSync fd, "    )\n"
    fs.writeSync fd, "  )\n"

  #
  # Write 3D shape file in VRML format
  #
  _generateVrml: (fd, pattern) ->
    x1 =  pattern.box.x - pattern.box.width/2
    x2 =  pattern.box.x + pattern.box.width/2
    y1 =  pattern.box.y - pattern.box.length/2
    y2 =  pattern.box.y + pattern.box.length/2
    z1 = 0
    z2 = pattern.box.height

    fs.writeSync fd, "#VRML V2.0 utf8\n"
    fs.writeSync fd, "Shape {\n"
    fs.writeSync fd, "  appearance Appearance {\n"
    fs.writeSync fd, "    material Material {\n"
    fs.writeSync fd, "    diffuseColor 0.37 0.37 0.37\n"
    fs.writeSync fd, "    emissiveColor 0.0 0.0 0.0\n"
    fs.writeSync fd, "    specularColor 1.0 1.0 1.0\n"
    fs.writeSync fd, "    ambientIntensity 1.0\n"
    fs.writeSync fd, "    transparency 0.5\n"
    fs.writeSync fd, "    shininess 1.0\n"
    fs.writeSync fd, "    }\n" # Material
    fs.writeSync fd, "  }\n" # Appearance

    fs.writeSync fd, "  geometry IndexedFaceSet {\n"
    fs.writeSync fd, "    coord Coordinate {\n"
    fs.writeSync fd, "      point [\n"
    fs.writeSync fd, "        #{x1} #{y1} #{z1},\n"
    fs.writeSync fd, "        #{x2} #{y1} #{z1},\n"
    fs.writeSync fd, "        #{x2} #{y2} #{z1},\n"
    fs.writeSync fd, "        #{x1} #{y2} #{z1},\n"
    fs.writeSync fd, "        #{x1} #{y1} #{z2},\n"
    fs.writeSync fd, "        #{x2} #{y1} #{z2},\n"
    fs.writeSync fd, "        #{x2} #{y2} #{z2},\n"
    fs.writeSync fd, "        #{x1} #{y2} #{z2}\n"
    fs.writeSync fd, "      ]\n" # point
    fs.writeSync fd, "    }\n" # Coordinate

    fs.writeSync fd, "    coordIndex [\n"
    fs.writeSync fd, "      0,1,2,3,-1\n" # bottom
    fs.writeSync fd, "      4,5,6,7,-1\n" # top
    fs.writeSync fd, "      0,1,5,4,-1\n" # front
    fs.writeSync fd, "      2,3,7,6,-1\n" # back
    fs.writeSync fd, "      0,3,7,4,-1\n" # left
    fs.writeSync fd, "      1,2,6,5,-1\n" # right
    fs.writeSync fd, "    ]\n" # coordIndex

    fs.writeSync fd, "  }\n" # IndexedFaceSet

    fs.writeSync fd, "}\n" # Shape

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

    if obj.orientation?
      obj.orientation = switch obj.orientation
        when 'left' then 180
        when 'right' then 0
        when 'up' then 90
        when 'down' then 270
        when 'horizontal' then 0
        when 'vertical' then 90
        else obj.orientation
    else
      obj.orientation = 0

    obj.type = 'unspecified'
    if obj.power or obj.ground
      obj.type = 'power_in' # Power input
      if obj.out then obj.type = 'power_out' # Power output
    else
      if obj.bidir or (obj.in and obj.out)
        obj.type = 'bidirectional' # Bidirectional
      else if obj.in
        obj.type = 'input' # Input
      else if obj.out
        obj.type = 'output' # Output
      else if obj.passive
        obj.type = 'passive' # Passive
      else if obj.nc
        obj.type = 'no_connect' # Not connected
      else if obj.z
        obj.type = 'tri_state' # Tristate
      else
        obj.type = 'unspecified' # Unspecified

    switch obj.fill
      when 'foreground' then obj.fillStyle = 'background'
      when 'background' then obj.fillStyle = 'outline'
      else obj.fillStyle = 'none'
    obj

module.exports = Kicad7Generator
