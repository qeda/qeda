fs = require 'fs'
mkdirp = require 'mkdirp'
sprintf = require('sprintf-js').sprintf

log = require './qeda-log'

#
# Generator of gEDA gschem symbols and gEDA pcb footprints
# gEDA gschem symbol file format is documented at http://wiki.geda-project.org/geda:file_format_spec
# gEDA pcb footprint file format is documented at http://pcb.geda-project.org/pcb-cvs/pcb.html#File-Formats
#
class GedaGenerator
  #
  # Constructor
  #
  constructor: (@library) ->
    @f = "%.#{@library.pattern.decimals}f"

  #
  # Generate symbol files
  #
  generate: (@name) ->
    # output directory for symbols
    dir = "./geda/symbols/#{@name}/"
    mkdirp.sync "#{dir}"

    # Symbols
    for element in @library.elements
      continue if (not element.symbols?) or 0 == element.symbols.length
      log.start "gEDA gschem symbol '#{element.name}'"
      @_generateSymbol dir, element
      log.ok()

    # output directory for footprints
    dir = "./geda/footprints/#{@name}/"
    mkdirp.sync "#{dir}"

    # Footprints
    for element in @library.elements
      continue if !element.pattern?
      log.start "gEDA pcb footprint '#{element.pattern.name}.fp'"
      fd = fs.openSync "#{dir}/#{element.pattern.name}.fp", 'w'
      @_generatePattern fd, element.pattern
      fs.closeSync fd
      log.ok()

  #
  # Write gEDA gschem symbol(s)
  #
  _generateSymbol: (dir, element) ->
    # qeda defines one symbol per element "part"
    # the equivalent gEDA gschem mechanism is called "slot"
    # pins can be different per slot, but not graphical elements
    # but qeda defines one rectangle per part, and it's not easy to find which pins are re-used
    # thus we will generate one symbol per part
    # see gEDA gschem convention for more information: http://wiki.geda-project.org/geda:gschem_symbol_creation
    combined = fs.openSync "#{dir}/#{element.name}.sym", 'w'
    fs.writeSync combined, "v 20150930 2\n" # use last know file format date


    for symbol in element.symbols
      symbol.invertVertical() # Positive vertical axis is pointing up
      symbol.alignToGrid(10);
      min_x = 0
      min_y = 0
      for shape in symbol.shapes
        continue unless shape.x? and shape.y?
        min_x = shape.x if shape.x < min_x
        min_y = shape.y if shape.y < min_y
      min_x = symbol.alignToGrid(min_x, 'floor')
      min_y = symbol.alignToGrid(min_y, 'floor')
      symbol.resize(100, true, -min_x, -min_y) # Resize to grid 100 (mil), and translate to 0, 0 (enforce at least this gEDA gschem convention)

      part_name = ""
      if element.symbols.length > 1
        part_name = "_part-#{element.symbols.indexOf(symbol)+1}-#{element.symbols.length}"
        part_name += "-#{symbol.name}" if symbol.name
      fd = fs.openSync "#{dir}/#{element.name}#{part_name}.sym", 'w'
      fs.writeSync fd, "v 20150930 2\n"

      for attribute in ['description', 'datasheet', 'keywords', 'aliases']
        continue if not element[attribute]?
        if element[attribute] instanceof Array
          if element[attribute].length > 0
            fs.writeSync fd, "T 0 0 5 8 0 0 0 0 1\n"
            fs.writeSync fd, "#{attribute}=#{element[attribute].join(' ')}\n"
        else
          fs.writeSync fd, "T 0 0 5 8 0 0 0 0 1\n"
          fs.writeSync fd, "#{attribute}=#{element[attribute]}\n"

      if element.pattern? and element.pattern.name?
        fs.writeSync fd, "T 0 0 5 8 0 0 0 0 1\n"
        fs.writeSync fd, "footprint=#{element.pattern.name}.fp\n"

      for shape in symbol.shapes
        # ignore all style attributes (lineWidth, fill, fontSize, ...) to keep it simple, and they are not commonly used
        switch shape.kind
          when 'rectangle'
            fs.writeSync fd, "B #{shape.x1} #{shape.y1} #{shape.x2-shape.x1} #{shape.y2-shape.y1} 3 0 1 0 -1 -1 0 -1 -1 -1 -1 -1\n"
          when 'line'
            fs.writeSync fd, "L #{shape.x1} #{shape.y1} #{shape.x2} #{shape.y2} 3 0 1 0 -1 -1\n"
          when 'circle'
            fs.writeSync fd, "V #{shape.x} #{shape.y} #{shape.radius} 3 0 0 0 -1 -1 0 -1 -1 -1 -1 -1\n"
          when 'arc'
            fs.writeSync fd, "A #{shape.x} #{shape.y} #{shape.radius} #{Math.round(shape.start)} #{Math.round(shape.end-shape.start)} 3 0 0 0 -1 -1\n"
          when 'pin'
            x1 = shape.x
            y1 = shape.y
            x2 = x1
            y2 = y1
            switch shape.orientation
              when 'right'
                x2 += shape.length
              when 'left'
                x2 -= shape.length
              when 'up'
                y2 += shape.length
              when 'down'
                y2 -= shape.length
            fs.writeSync fd, "P #{x1} #{y1} #{x2} #{y2} 1 0 0\n"
            # write pin attributes
            fs.writeSync fd, "{\n"
            # pin label and type
            xt = x2
            yt = y2
            angle = 0
            alignment = 0
            switch shape.orientation
              when 'right'
                xt += shape.space
              when 'left'
                xt -= shape.space
                alignment = 6
              when 'up'
                yt += shape.space
                angle = 90
              when 'down'
                yt -= shape.space
                angle = 90
                alignment = 6
            name = shape.name.toString()
            if name.includes('~')
              name = name.replace /~{([^}]+)}/g, '\\_$1\\_'
              name = name.replace /~([^~]+)~/g, '\\_$1\\_'
              name = name.replace /~([^~]+)/g, '\\_$1\\_'
            if shape.inverted
              name = "\\_#{name}\\_"
            fs.writeSync fd, "T #{xt} #{yt} 9 8 #{if element.schematic.showPinNames then 1 else 0} 1 #{angle} #{alignment} 1\n"
            fs.writeSync fd, "pinlabel=#{name}\n"
            pintype = false
            if shape.bidir
              pintype = "io"
            else if shape.ground or shape.power
              pintype = "pwr"
            else if shape.in
              pintype = "in"
            else if shape.out
              pintype = "out"
            else if shape.passive
              pintype = "pas"
            else if shape.z
              pintype = "tri"
            if pintype?
              fs.writeSync fd, "T #{xt} #{yt} 5 8 0 0 #{angle} #{alignment+2} 1\n"
              fs.writeSync fd, "pintype=#{pintype}\n"
            # pin number and sequence
            xt = x2
            yt = y2
            angle = 0
            alignment = 0
            switch shape.orientation
              when 'right'
                xt -= shape.space
                alignment = 6
              when 'left'
                xt += shape.space
              when 'up'
                yt -= shape.space
                angle = 90
                alignment = 6
              when 'down'
                yt += shape.space
                angle = 90
            fs.writeSync fd, "T #{xt} #{yt} 5 8 #{if element.schematic.showPinNumbers then 1 else 0} 1 #{angle} #{alignment} 1\n"
            fs.writeSync fd, "pinnumber=#{shape.number}\n"
            fs.writeSync fd, "T #{xt} #{yt} 5 8 0 0 #{angle} #{alignment+2} 1\n"
            fs.writeSync fd, "pinseq=#{shape.number}\n"
            # end pin attributes
            fs.writeSync fd, "}\n"
          when 'poly'
            fs.writeSync fd, "H 3 5 0 0 -1 -1 0 -1 -1 -1 -1 -1 #{shape.points.length/2+1}\n"
            for i from [0..(shape.points.length-1)]
               if i % 2 == 0
                 fs.writeSync fd, "#{if i == 0 then 'M' else 'L'} #{shape.points[i]} #{shape.points[i+1]}\n"
            fs.writeSync fd, "z\n"
           when 'text'
             alignment = switch shape.valign
               when 'bottom' then 0
               when 'center' then 1
               when 'top' then 2
               else 0
             alignment += switch shape.halign
               when 'left' then 0
               when 'center' then 3
               when 'right' then 6
               else 0
             fs.writeSync fd, "T #{shape.x} #{shape.y} 9 10 1 0 0 #{alignment} 1\n"
             fs.writeSync fd, "#{shape.text}\n"
           when 'attribute'
             alignment = switch shape.valign
               when 'bottom' then 0
               when 'center' then 1
               when 'top' then 2
               else 0
             alignment += switch shape.halign
               when 'left' then 0
               when 'center' then 3
               when 'right' then 6
               else 0
             color = if shape.name is 'name' then 9 else 5
             name = switch shape.name
               when 'refDes' then 'refdes'
               when 'name' then 'device'
               else shape.name.toLowerCase
             if element[shape.name]
               fs.writeSync fd, "T #{shape.x} #{shape.y} #{color} 10 1 1 0 #{alignment} 1\n"
               value = element[shape.name]
               value += "?" if name is 'refdes'
               fs.writeSync fd, "#{name}=#{value}\n"

  #
  # Write gEDA pcb pattern file
  #
  _generatePattern: (fd, pattern) ->
    now = new Date
    timestamp = sprintf "%d-%02d-%02d %02d:%02d:%02d",
      now.getYear() + 1900, now.getMonth() + 1, now.getDate(),
      now.getHours(), now.getMinutes(), now.getSeconds()
    fs.writeSync fd, "# footprint generated using qeda on #{timestamp}\n"
    pattern.attributes.refDes.text ?= "REF**"
    fs.writeSync fd, 'Element ["" "'+pattern.name+'" "'+pattern.attributes.refDes.text+'" "" 0 0 0 0 0 100 ""]'+"\n"
    fs.writeSync fd, '('+"\n"
    for shape in pattern.shapes
      switch shape.kind
        when 'attribute'
          continue if not shape.text
          fs.writeSync(fd,
            sprintf("  Attribute (\"%s\" \"%s\")\n",
              shape.name, shape.text)
          )
        when 'circle'
          continue if not shape.layer.includes("topSilkscreen")
          fs.writeSync(fd,
            sprintf("  ElementArc [#{@f}mm #{@f}mm #{@f}mm #{@f}mm 0 360 #{@f}mm]\n",
              shape.x, shape.y, shape.radius, shape.radius, shape.lineWidth)
          )
        when 'line'
          continue if not shape.layer.includes("topSilkscreen")
          fs.writeSync(fd,
            sprintf("  ElementLine [#{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm]\n",
              shape.x1, shape.y1, shape.x2, shape.y2, shape.lineWidth)
          )
        when 'pad'
          shape.clearance ?= pattern.settings.clearance.padToPad
          shape.mask ?= pattern.settings.clearance.padToMask
          if (shape.type is 'through-hole' or shape.type is 'mounting-hole')
            flags = []
            hole = 0
            thickness = 0
            mask = 0
            # gEDA pcb Pin shapes are very restrictive: the don't allow slots or oblong annulus
            if shape.hole? # a hole
              hole = shape.hole
              # use smallest dimension, and let the next section draw the rectangle part
              if shape.width <= shape.hole and shape.height <= shape.hole
                thickness = 0
              else if shape.width == shape.height
                thickness = shape.width
              else if shape.width < shape.height
                thickness = shape.width
              else
                thickness = shape.height
              shape.type = 'smd' # let the next section handle drawing the non-square pad
            else if shape.slotWidth? and shape.slotHeight? # a slot
              if shape.slotWidth > shape.slotHeight
                hole = shape.slotWidth
                thickness = shape.width
              else
                hole = shape.slotHeight
                thickness = shape.height
            if shape.shape is 'rectangle' then flags.push('square')
            if thickness <= hole and shape.height <= hole
              thickness = 0
              flags.push('hole')
            mask = if (thickness == 0) then 0 else thickness+2*shape.mask
            fs.writeSync(fd,
              sprintf("  Pin [#{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm \"\" \"%s\" \"%s\"]\n",
                shape.x, shape.y, thickness, shape.clearance, mask, hole, shape.name, flags.join(','))
            )
          if (shape.type is 'smd')
            shape.shape = 'rounded' if pattern.settings.smoothPadCorners and pattern.settings.maximum.cornerRadius>0.0
            width = 0
            x1 = shape.x
            x2 = shape.x
            y1 = shape.y
            y2 = shape.y
            if (shape.width < shape.height)
              width = shape.width
              y1 = shape.y-shape.height/2.0+shape.width/2.0
              y2 = shape.y+shape.height/2.0-shape.width/2.0
            else
              width = shape.height
              x1 = shape.x-shape.width/2.0+shape.height/2.0
              x2 = shape.x+shape.width/2.0-shape.height/2.0
            mask = width+2*shape.mask
            if shape.layer.includes("topCopper")
              flags = []
              if shape.shape is 'rectangle' then flags.push('square')
              if not shape.layer.includes("topMask") then mask = 0
              if not shape.layer.includes("topPaste") then flags.push('nopaste')
              fs.writeSync(fd,
                sprintf("  Pad [#{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm \"\" \"%s\" \"%s\"]\n",
                  x1, y1, x2, y2, width, shape.clearance, mask, shape.name, flags.join(','))
              )
            if shape.layer.includes("bottomCopper")
              flags = ['solder']
              if shape.shape is 'rectangle' then flags.push('square')
              if not shape.layer.includes("bottomMask") then mask = 0
              if not shape.layer.includes("bottomPaste") then flags.push('nopaste')
              fs.writeSync(fd,
                sprintf("  Pad [#{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm \"\" \"%s\" \"%s\"]\n",
                  x1, y1, x2, y2, width, shape.clearance, mask, shape.name, flags.join(','))
              )
        when 'rectangle'
          continue if not shape.layer.includes("topSilkscreen")
          fs.writeSync(fd,
            sprintf("  ElementLine [#{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm]\n",
              shape.x1, shape.y1, shape.x2, shape.y1, shape.lineWidth)
          )
          fs.writeSync(fd,
            sprintf("  ElementLine [#{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm]\n",
              shape.x2, shape.y1, shape.x2, shape.y2, shape.lineWidth)
          )
          fs.writeSync(fd,
            sprintf("  ElementLine [#{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm]\n",
              shape.x2, shape.y2, shape.x1, shape.y2, shape.lineWidth)
          )
          fs.writeSync(fd,
            sprintf("  ElementLine [#{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm]\n",
              shape.x1, shape.y2, shape.x1, shape.y1, shape.lineWidth)
          )

    fs.writeSync fd, ")\n" # end of Element
module.exports = GedaGenerator
