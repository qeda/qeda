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
      else if pattern.box.height > 0
        log.start "KiCad 3D shape '#{patternName}.stp'"
        fd = fs.openSync "#{dir}/#{@name}.3dshapes/#{patternName}.stp", 'w'
        @_generateStep fd, pattern, patternName
        fs.closeSync fd
      log.ok()

  #
  # Write pattern file
  #
  _generatePattern: (fd, pattern) ->
    fs.writeSync fd, "(module #{pattern.name} (layer F.Cu)\n"
    attrs = []
    if pattern.type is 'smd' then attrs.push 'smd'
    else if pattern.type.endsWith('hole') then attrs.push 'through_hole'
    if pattern.nobom? then attrs.push 'exclude_from_bom'
    if attrs.length > 0
      fs.writeSync fd, sprintf "  (attr #{attrs.join(' ')})\n"
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
            sprintf("  (fp_circle (center #{@f} #{@f}) (end #{@f} #{@f}) (layer %s) (width #{@f})",
              patObj.x, patObj.y, patObj.x, patObj.y + patObj.radius, patObj.layer, patObj.lineWidth)
          )
          if patObj.fill
            fs.writeSync(fd, " (fill solid)")
          fs.writeSync(fd, ")\n")
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
          else if patObj.chamfer?
            cornerRadius = 0
            patObj.shape = 'roundrect'

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
          if patObj.clearance? then fs.writeSync fd, sprintf("\n    (clearance #{@f})", patObj.clearance)

          if patObj.shape is 'roundrect'
            ratio = cornerRadius / Math.min(patObj.width, patObj.height)
            fs.writeSync fd, sprintf("\n    (roundrect_rratio #{@f})", ratio)

          if patObj.chamfer? and patObj.chamfer.length > 0
            chamfer = patObj.chamfer_ratio
            chamfer ?= 0.5
            if chamfer > 1 then chamfer = 1
            if chamfer < 0 then chamfer = 0
            fs.writeSync fd, sprintf("\n    (chamfer_ratio #{@f}) (chamfer %s)", chamfer, @_formatChamfer patObj.chamfer)

          if patObj.property? and patObj.property is 'testpoint'
            fs.writeSync fd, sprintf("\n    (property pad_prop_testpoint)")

          fs.writeSync fd, ")\n"
        when 'rectangle'
          fs.writeSync(fd,
            sprintf("  (fp_rect (start #{@f} #{@f}) (end #{@f} #{@f}) (layer %s) (width #{@f})",
              patObj.x1, patObj.y1, patObj.x2, patObj.y2, patObj.layer, patObj.lineWidth)
          )
          if patObj.fill
            fs.writeSync(fd, " (fill solid)")
          fs.writeSync(fd, ")\n")

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
    else if pattern.box.height > 0
      xpos = pattern.box.x - pattern.box.width / 2
      ypos = pattern.box.y - pattern.box.length / 2
      fs.writeSync fd, "  (model ../#{@name}.3dshapes/#{pattern.name}.stp\n"
      fs.writeSync fd, "    (at (xyz #{xpos / 25.4} #{ypos / 25.4} 0))\n"
      fs.writeSync fd, "    (scale (xyz 1 1 1))\n"
      fs.writeSync fd, "    (rotate (xyz 0 0 0 ))\n"
    fs.writeSync fd, "  )\n" # model

    fs.writeSync fd, ")\n" # module

  #
  # Format pin names for KiCad 7
  #
  _formatPinName: (name) ->
    formatted = String(name).replace /~([^~{}]+)~/g, '~{$1}'
    formatted = formatted.replace /~([^~{}]+)/g, '~{$1}'
    return formatted

  #
  # Format numeric value for STEP
  #
  _formatStepVal: (val) -> val.toFixed(12).replace /0+$/, ''

  #
  # Format chamfer string for KiCad 7
  _formatChamfer: (list) ->
    ret = []
    if 'TopLeft' in list
      ret.push 'top_left'
    if 'TopRight' in list
      ret.push 'top_right'
    if 'BotLeft' in list
      ret.push 'bottom_left'
    if 'BotRight' in list
      ret.push 'bottom_right'
    return ret.join ' '

  #
  # Write symbol file
  #
  _generateSymbol: (fd, element) ->
    for symbol in element.symbols
      symbol.resize 50 * 0.0254, false # Resize to grid 50 mil, in mm
      symbol.invertVertical() # Positive vertical axis is pointing up in KiCad

    # Write symbol name
    fs.writeSync fd, "  (symbol \"#{element.name}"
    if element.overriden?
      fs.writeSync fd, "_#{element.overriden}"
    fs.writeSync fd, "\""
    if element.power == true
      fs.writeSync fd, " (power)"
    if element.schematic?.showPinNumbers == false
      fs.writeSync fd, " (pin_numbers hide)"
    if element.schematic?.showPinNames == false
      fs.writeSync fd, " (pin_names hide)"
    if element.power == true
      fs.writeSync fd, " (in_bom no) (on_board no)\n"
    else if element.schematic.nobom?
      fs.writeSync fd, " (in_bom no) (on_board yes)\n"
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
      fs.writeSync fd, "    (property \"MPN\" \"#{element.name}\" (at 0 0 0)\n"
      fs.writeSync fd, "      (effects (font (size #{nameObj.fontSize} #{nameObj.fontSize})) hide)\n"
      fs.writeSync fd, "    )\n"

    if element.manufacturer?
      fs.writeSync fd, "    (property \"Manufacturer\" \"#{element.manufacturer}\" (at 0 0 0)\n"
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
            if symObj.alternates? and symObj.alternates.length > 0
              for alternate in symObj.alternates
                fs.writeSync fd, "        (alternate \"#{@_formatPinName(alternate.name)}\" #{alternate.type || symObj.type} line)\n"
            fs.writeSync fd, "      )\n"
      fs.writeSync fd, "    )\n"
    fs.writeSync fd, "  )\n"

  #
  # Write 3D shape file in STEP format
  #
  _generateStep: (fd, pattern, name) ->
    xpos1 = @_formatStepVal pattern.box.x * -1
    ypos1 = @_formatStepVal pattern.box.y * -1
    zpos1 = @_formatStepVal 0
    xpos2 = @_formatStepVal pattern.box.width
    ypos2 = @_formatStepVal pattern.box.length
    zpos2 = @_formatStepVal pattern.box.height

    fs.writeSync fd, "ISO-10303-21;\r\n"
    fs.writeSync fd, "HEADER;\r\n"
    fs.writeSync fd, "FILE_DESCRIPTION(('Simplified model for #{name}'),'2;1');\r\n"
    fs.writeSync fd, "FILE_NAME('#{name}','#{(if @library.nodate then new Date(0) else new Date).toISOString().slice 0, -2}',(''),(''),\r\n"
    fs.writeSync fd, "  'QEDA','QEDA','Unknown');\r\n"
    fs.writeSync fd, "FILE_SCHEMA(('AUTOMOTIVE_DESIGN { 1 0 10303 214 1 1 1 1 }'));\r\n"
    fs.writeSync fd, "ENDSEC;\r\n"
    fs.writeSync fd, "DATA;\r\n"
    fs.writeSync fd, "#1 = APPLICATION_PROTOCOL_DEFINITION('international standard',\r\n"
    fs.writeSync fd, "  'automotive_design',2000,#2);\r\n"
    fs.writeSync fd, "#2 = APPLICATION_CONTEXT(\r\n"
    fs.writeSync fd, "  'core data for automotive mechanical design processes');\r\n"
    fs.writeSync fd, "#3 = SHAPE_DEFINITION_REPRESENTATION(#4,#10);\r\n"
    fs.writeSync fd, "#4 = PRODUCT_DEFINITION_SHAPE('','',#5);\r\n"
    fs.writeSync fd, "#5 = PRODUCT_DEFINITION('design','',#6,#9);\r\n"
    fs.writeSync fd, "#6 = PRODUCT_DEFINITION_FORMATION('','',#7);\r\n"
    fs.writeSync fd, "#7 = PRODUCT('#{name}','#{name}','',(#8));\r\n"
    fs.writeSync fd, "#8 = PRODUCT_CONTEXT('',#2,'mechanical');\r\n"
    fs.writeSync fd, "#9 = PRODUCT_DEFINITION_CONTEXT('part definition',#2,'design');\r\n"
    fs.writeSync fd, "#10 = ADVANCED_BREP_SHAPE_REPRESENTATION('',(#11,#15),#165);\r\n"
    fs.writeSync fd, "#11 = AXIS2_PLACEMENT_3D('',#12,#13,#14);\r\n"
    fs.writeSync fd, "#12 = CARTESIAN_POINT('',(#{xpos1},#{ypos1},#{zpos1}));\r\n"
    fs.writeSync fd, "#13 = DIRECTION('',(0.,0.,1.));\r\n"
    fs.writeSync fd, "#14 = DIRECTION('',(1.,0.,-0.));\r\n"
    fs.writeSync fd, "#15 = MANIFOLD_SOLID_BREP('',#16);\r\n"
    fs.writeSync fd, "#16 = CLOSED_SHELL('',(#17,#57,#97,#119,#141,#153));\r\n"
    fs.writeSync fd, "#17 = ADVANCED_FACE('',(#18),#52,.F.);\r\n"
    fs.writeSync fd, "#18 = FACE_BOUND('',#19,.F.);\r\n"
    fs.writeSync fd, "#19 = EDGE_LOOP('',(#20,#30,#38,#46));\r\n"
    fs.writeSync fd, "#20 = ORIENTED_EDGE('',*,*,#21,.F.);\r\n"
    fs.writeSync fd, "#21 = EDGE_CURVE('',#22,#24,#26,.T.);\r\n"
    fs.writeSync fd, "#22 = VERTEX_POINT('',#23);\r\n"
    fs.writeSync fd, "#23 = CARTESIAN_POINT('',(#{xpos1},#{ypos1},#{zpos1}));\r\n"
    fs.writeSync fd, "#24 = VERTEX_POINT('',#25);\r\n"
    fs.writeSync fd, "#25 = CARTESIAN_POINT('',(#{xpos1},#{ypos1},#{zpos2}));\r\n"
    fs.writeSync fd, "#26 = LINE('',#27,#28);\r\n"
    fs.writeSync fd, "#27 = CARTESIAN_POINT('',(#{xpos1},#{ypos1},#{zpos1}));\r\n"
    fs.writeSync fd, "#28 = VECTOR('',#29,1.);\r\n"
    fs.writeSync fd, "#29 = DIRECTION('',(0.,0.,1.));\r\n"
    fs.writeSync fd, "#30 = ORIENTED_EDGE('',*,*,#31,.T.);\r\n"
    fs.writeSync fd, "#31 = EDGE_CURVE('',#22,#32,#34,.T.);\r\n"
    fs.writeSync fd, "#32 = VERTEX_POINT('',#33);\r\n"
    fs.writeSync fd, "#33 = CARTESIAN_POINT('',(#{xpos1},#{ypos2},#{zpos1}));\r\n"
    fs.writeSync fd, "#34 = LINE('',#35,#36);\r\n"
    fs.writeSync fd, "#35 = CARTESIAN_POINT('',(#{xpos1},#{ypos1},#{zpos1}));\r\n"
    fs.writeSync fd, "#36 = VECTOR('',#37,1.);\r\n"
    fs.writeSync fd, "#37 = DIRECTION('',(-0.,1.,0.));\r\n"
    fs.writeSync fd, "#38 = ORIENTED_EDGE('',*,*,#39,.T.);\r\n"
    fs.writeSync fd, "#39 = EDGE_CURVE('',#32,#40,#42,.T.);\r\n"
    fs.writeSync fd, "#40 = VERTEX_POINT('',#41);\r\n"
    fs.writeSync fd, "#41 = CARTESIAN_POINT('',(#{xpos1},#{ypos2},#{zpos2}));\r\n"
    fs.writeSync fd, "#42 = LINE('',#43,#44);\r\n"
    fs.writeSync fd, "#43 = CARTESIAN_POINT('',(#{xpos1},#{ypos2},#{zpos1}));\r\n"
    fs.writeSync fd, "#44 = VECTOR('',#45,1.);\r\n"
    fs.writeSync fd, "#45 = DIRECTION('',(0.,0.,1.));\r\n"
    fs.writeSync fd, "#46 = ORIENTED_EDGE('',*,*,#47,.F.);\r\n"
    fs.writeSync fd, "#47 = EDGE_CURVE('',#24,#40,#48,.T.);\r\n"
    fs.writeSync fd, "#48 = LINE('',#49,#50);\r\n"
    fs.writeSync fd, "#49 = CARTESIAN_POINT('',(#{xpos1},#{ypos1},#{zpos2}));\r\n"
    fs.writeSync fd, "#50 = VECTOR('',#51,1.);\r\n"
    fs.writeSync fd, "#51 = DIRECTION('',(-0.,1.,0.));\r\n"
    fs.writeSync fd, "#52 = PLANE('',#53);\r\n"
    fs.writeSync fd, "#53 = AXIS2_PLACEMENT_3D('',#54,#55,#56);\r\n"
    fs.writeSync fd, "#54 = CARTESIAN_POINT('',(#{xpos1},#{ypos1},#{zpos1}));\r\n"
    fs.writeSync fd, "#55 = DIRECTION('',(1.,0.,-0.));\r\n"
    fs.writeSync fd, "#56 = DIRECTION('',(0.,0.,1.));\r\n"
    fs.writeSync fd, "#57 = ADVANCED_FACE('',(#58),#92,.T.);\r\n"
    fs.writeSync fd, "#58 = FACE_BOUND('',#59,.T.);\r\n"
    fs.writeSync fd, "#59 = EDGE_LOOP('',(#60,#70,#78,#86));\r\n"
    fs.writeSync fd, "#60 = ORIENTED_EDGE('',*,*,#61,.F.);\r\n"
    fs.writeSync fd, "#61 = EDGE_CURVE('',#62,#64,#66,.T.);\r\n"
    fs.writeSync fd, "#62 = VERTEX_POINT('',#63);\r\n"
    fs.writeSync fd, "#63 = CARTESIAN_POINT('',(#{xpos2},#{ypos1},#{zpos1}));\r\n"
    fs.writeSync fd, "#64 = VERTEX_POINT('',#65);\r\n"
    fs.writeSync fd, "#65 = CARTESIAN_POINT('',(#{xpos2},#{ypos1},#{zpos2}));\r\n"
    fs.writeSync fd, "#66 = LINE('',#67,#68);\r\n"
    fs.writeSync fd, "#67 = CARTESIAN_POINT('',(#{xpos2},#{ypos1},#{zpos1}));\r\n"
    fs.writeSync fd, "#68 = VECTOR('',#69,1.);\r\n"
    fs.writeSync fd, "#69 = DIRECTION('',(0.,0.,1.));\r\n"
    fs.writeSync fd, "#70 = ORIENTED_EDGE('',*,*,#71,.T.);\r\n"
    fs.writeSync fd, "#71 = EDGE_CURVE('',#62,#72,#74,.T.);\r\n"
    fs.writeSync fd, "#72 = VERTEX_POINT('',#73);\r\n"
    fs.writeSync fd, "#73 = CARTESIAN_POINT('',(#{xpos2},#{ypos2},#{zpos1}));\r\n"
    fs.writeSync fd, "#74 = LINE('',#75,#76);\r\n"
    fs.writeSync fd, "#75 = CARTESIAN_POINT('',(#{xpos2},#{ypos1},#{zpos1}));\r\n"
    fs.writeSync fd, "#76 = VECTOR('',#77,1.);\r\n"
    fs.writeSync fd, "#77 = DIRECTION('',(-0.,1.,0.));\r\n"
    fs.writeSync fd, "#78 = ORIENTED_EDGE('',*,*,#79,.T.);\r\n"
    fs.writeSync fd, "#79 = EDGE_CURVE('',#72,#80,#82,.T.);\r\n"
    fs.writeSync fd, "#80 = VERTEX_POINT('',#81);\r\n"
    fs.writeSync fd, "#81 = CARTESIAN_POINT('',(#{xpos2},#{ypos2},#{zpos2}));\r\n"
    fs.writeSync fd, "#82 = LINE('',#83,#84);\r\n"
    fs.writeSync fd, "#83 = CARTESIAN_POINT('',(#{xpos2},#{ypos2},#{zpos1}));\r\n"
    fs.writeSync fd, "#84 = VECTOR('',#85,1.);\r\n"
    fs.writeSync fd, "#85 = DIRECTION('',(0.,0.,1.));\r\n"
    fs.writeSync fd, "#86 = ORIENTED_EDGE('',*,*,#87,.F.);\r\n"
    fs.writeSync fd, "#87 = EDGE_CURVE('',#64,#80,#88,.T.);\r\n"
    fs.writeSync fd, "#88 = LINE('',#89,#90);\r\n"
    fs.writeSync fd, "#89 = CARTESIAN_POINT('',(#{xpos2},#{ypos1},#{zpos2}));\r\n"
    fs.writeSync fd, "#90 = VECTOR('',#91,1.);\r\n"
    fs.writeSync fd, "#91 = DIRECTION('',(-0.,1.,0.));\r\n"
    fs.writeSync fd, "#92 = PLANE('',#93);\r\n"
    fs.writeSync fd, "#93 = AXIS2_PLACEMENT_3D('',#94,#95,#96);\r\n"
    fs.writeSync fd, "#94 = CARTESIAN_POINT('',(#{xpos2},#{ypos1},#{zpos1}));\r\n"
    fs.writeSync fd, "#95 = DIRECTION('',(1.,0.,-0.));\r\n"
    fs.writeSync fd, "#96 = DIRECTION('',(0.,0.,1.));\r\n"
    fs.writeSync fd, "#97 = ADVANCED_FACE('',(#98),#114,.F.);\r\n"
    fs.writeSync fd, "#98 = FACE_BOUND('',#99,.F.);\r\n"
    fs.writeSync fd, "#99 = EDGE_LOOP('',(#100,#106,#107,#113));\r\n"
    fs.writeSync fd, "#100 = ORIENTED_EDGE('',*,*,#101,.F.);\r\n"
    fs.writeSync fd, "#101 = EDGE_CURVE('',#22,#62,#102,.T.);\r\n"
    fs.writeSync fd, "#102 = LINE('',#103,#104);\r\n"
    fs.writeSync fd, "#103 = CARTESIAN_POINT('',(#{xpos1},#{ypos1},#{zpos1}));\r\n"
    fs.writeSync fd, "#104 = VECTOR('',#105,1.);\r\n"
    fs.writeSync fd, "#105 = DIRECTION('',(1.,0.,-0.));\r\n"
    fs.writeSync fd, "#106 = ORIENTED_EDGE('',*,*,#21,.T.);\r\n"
    fs.writeSync fd, "#107 = ORIENTED_EDGE('',*,*,#108,.T.);\r\n"
    fs.writeSync fd, "#108 = EDGE_CURVE('',#24,#64,#109,.T.);\r\n"
    fs.writeSync fd, "#109 = LINE('',#110,#111);\r\n"
    fs.writeSync fd, "#110 = CARTESIAN_POINT('',(#{xpos1},#{ypos1},#{zpos2}));\r\n"
    fs.writeSync fd, "#111 = VECTOR('',#112,1.);\r\n"
    fs.writeSync fd, "#112 = DIRECTION('',(1.,0.,-0.));\r\n"
    fs.writeSync fd, "#113 = ORIENTED_EDGE('',*,*,#61,.F.);\r\n"
    fs.writeSync fd, "#114 = PLANE('',#115);\r\n"
    fs.writeSync fd, "#115 = AXIS2_PLACEMENT_3D('',#116,#117,#118);\r\n"
    fs.writeSync fd, "#116 = CARTESIAN_POINT('',(#{xpos1},#{ypos1},#{zpos1}));\r\n"
    fs.writeSync fd, "#117 = DIRECTION('',(-0.,1.,0.));\r\n"
    fs.writeSync fd, "#118 = DIRECTION('',(0.,0.,1.));\r\n"
    fs.writeSync fd, "#119 = ADVANCED_FACE('',(#120),#136,.T.);\r\n"
    fs.writeSync fd, "#120 = FACE_BOUND('',#121,.T.);\r\n"
    fs.writeSync fd, "#121 = EDGE_LOOP('',(#122,#128,#129,#135));\r\n"
    fs.writeSync fd, "#122 = ORIENTED_EDGE('',*,*,#123,.F.);\r\n"
    fs.writeSync fd, "#123 = EDGE_CURVE('',#32,#72,#124,.T.);\r\n"
    fs.writeSync fd, "#124 = LINE('',#125,#126);\r\n"
    fs.writeSync fd, "#125 = CARTESIAN_POINT('',(#{xpos1},#{ypos2},#{zpos1}));\r\n"
    fs.writeSync fd, "#126 = VECTOR('',#127,1.);\r\n"
    fs.writeSync fd, "#127 = DIRECTION('',(1.,0.,-0.));\r\n"
    fs.writeSync fd, "#128 = ORIENTED_EDGE('',*,*,#39,.T.);\r\n"
    fs.writeSync fd, "#129 = ORIENTED_EDGE('',*,*,#130,.T.);\r\n"
    fs.writeSync fd, "#130 = EDGE_CURVE('',#40,#80,#131,.T.);\r\n"
    fs.writeSync fd, "#131 = LINE('',#132,#133);\r\n"
    fs.writeSync fd, "#132 = CARTESIAN_POINT('',(#{xpos1},#{ypos2},#{zpos2}));\r\n"
    fs.writeSync fd, "#133 = VECTOR('',#134,1.);\r\n"
    fs.writeSync fd, "#134 = DIRECTION('',(1.,0.,-0.));\r\n"
    fs.writeSync fd, "#135 = ORIENTED_EDGE('',*,*,#79,.F.);\r\n"
    fs.writeSync fd, "#136 = PLANE('',#137);\r\n"
    fs.writeSync fd, "#137 = AXIS2_PLACEMENT_3D('',#138,#139,#140);\r\n"
    fs.writeSync fd, "#138 = CARTESIAN_POINT('',(#{xpos1},#{ypos2},#{zpos1}));\r\n"
    fs.writeSync fd, "#139 = DIRECTION('',(-0.,1.,0.));\r\n"
    fs.writeSync fd, "#140 = DIRECTION('',(0.,0.,1.));\r\n"
    fs.writeSync fd, "#141 = ADVANCED_FACE('',(#142),#148,.F.);\r\n"
    fs.writeSync fd, "#142 = FACE_BOUND('',#143,.F.);\r\n"
    fs.writeSync fd, "#143 = EDGE_LOOP('',(#144,#145,#146,#147));\r\n"
    fs.writeSync fd, "#144 = ORIENTED_EDGE('',*,*,#31,.F.);\r\n"
    fs.writeSync fd, "#145 = ORIENTED_EDGE('',*,*,#101,.T.);\r\n"
    fs.writeSync fd, "#146 = ORIENTED_EDGE('',*,*,#71,.T.);\r\n"
    fs.writeSync fd, "#147 = ORIENTED_EDGE('',*,*,#123,.F.);\r\n"
    fs.writeSync fd, "#148 = PLANE('',#149);\r\n"
    fs.writeSync fd, "#149 = AXIS2_PLACEMENT_3D('',#150,#151,#152);\r\n"
    fs.writeSync fd, "#150 = CARTESIAN_POINT('',(#{xpos1},#{ypos1},#{zpos1}));\r\n"
    fs.writeSync fd, "#151 = DIRECTION('',(0.,0.,1.));\r\n"
    fs.writeSync fd, "#152 = DIRECTION('',(1.,0.,-0.));\r\n"
    fs.writeSync fd, "#153 = ADVANCED_FACE('',(#154),#160,.T.);\r\n"
    fs.writeSync fd, "#154 = FACE_BOUND('',#155,.T.);\r\n"
    fs.writeSync fd, "#155 = EDGE_LOOP('',(#156,#157,#158,#159));\r\n"
    fs.writeSync fd, "#156 = ORIENTED_EDGE('',*,*,#47,.F.);\r\n"
    fs.writeSync fd, "#157 = ORIENTED_EDGE('',*,*,#108,.T.);\r\n"
    fs.writeSync fd, "#158 = ORIENTED_EDGE('',*,*,#87,.T.);\r\n"
    fs.writeSync fd, "#159 = ORIENTED_EDGE('',*,*,#130,.F.);\r\n"
    fs.writeSync fd, "#160 = PLANE('',#161);\r\n"
    fs.writeSync fd, "#161 = AXIS2_PLACEMENT_3D('',#162,#163,#164);\r\n"
    fs.writeSync fd, "#162 = CARTESIAN_POINT('',(#{xpos1},#{ypos1},#{zpos2}));\r\n"
    fs.writeSync fd, "#163 = DIRECTION('',(0.,0.,1.));\r\n"
    fs.writeSync fd, "#164 = DIRECTION('',(1.,0.,-0.));\r\n"
    fs.writeSync fd, "#165 = ( GEOMETRIC_REPRESENTATION_CONTEXT(3) \r\n"
    fs.writeSync fd, "GLOBAL_UNCERTAINTY_ASSIGNED_CONTEXT((#169)) GLOBAL_UNIT_ASSIGNED_CONTEXT\r\n"
    fs.writeSync fd, "((#166,#167,#168)) REPRESENTATION_CONTEXT('Context #1',\r\n"
    fs.writeSync fd, "  '3D Context with UNIT and UNCERTAINTY') );\r\n"
    fs.writeSync fd, "#166 = ( LENGTH_UNIT() NAMED_UNIT(*) SI_UNIT(.MILLI.,.METRE.) );\r\n"
    fs.writeSync fd, "#167 = ( NAMED_UNIT(*) PLANE_ANGLE_UNIT() SI_UNIT($,.RADIAN.) );\r\n"
    fs.writeSync fd, "#168 = ( NAMED_UNIT(*) SI_UNIT($,.STERADIAN.) SOLID_ANGLE_UNIT() );\r\n"
    fs.writeSync fd, "#169 = UNCERTAINTY_MEASURE_WITH_UNIT(LENGTH_MEASURE(1.E-07),#166,\r\n"
    fs.writeSync fd, "  'distance_accuracy_value','confusion accuracy');\r\n"
    fs.writeSync fd, "#170 = PRODUCT_RELATED_PRODUCT_CATEGORY('part',$,(#7));\r\n"
    fs.writeSync fd, "#171 = MECHANICAL_DESIGN_GEOMETRIC_PRESENTATION_REPRESENTATION('',(#172)\r\n"
    fs.writeSync fd, "  ,#165);\r\n"
    fs.writeSync fd, "#172 = STYLED_ITEM('color',(#173),#15);\r\n"
    fs.writeSync fd, "#173 = PRESENTATION_STYLE_ASSIGNMENT((#174,#180));\r\n"
    fs.writeSync fd, "#174 = SURFACE_STYLE_USAGE(.BOTH.,#175);\r\n"
    fs.writeSync fd, "#175 = SURFACE_SIDE_STYLE('',(#176));\r\n"
    fs.writeSync fd, "#176 = SURFACE_STYLE_FILL_AREA(#177);\r\n"
    fs.writeSync fd, "#177 = FILL_AREA_STYLE('',(#178));\r\n"
    fs.writeSync fd, "#178 = FILL_AREA_STYLE_COLOUR('',#179);\r\n"
    fs.writeSync fd, "#179 = COLOUR_RGB('',0.23,0.23,0.23);\r\n"
    fs.writeSync fd, "#180 = CURVE_STYLE('',#181,POSITIVE_LENGTH_MEASURE(0.1),#182);\r\n"
    fs.writeSync fd, "#181 = DRAUGHTING_PRE_DEFINED_CURVE_FONT('continuous');\r\n"
    fs.writeSync fd, "#182 = DRAUGHTING_PRE_DEFINED_COLOUR('black');\r\n"
    fs.writeSync fd, "ENDSEC;\r\n"
    fs.writeSync fd, "END-ISO-10303-21;\r\n"

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
