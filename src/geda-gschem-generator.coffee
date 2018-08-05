fs = require 'fs'
mkdirp = require 'mkdirp'
sprintf = require('sprintf-js').sprintf

log = require './qeda-log'

#
# Generator of symbol in gEDA gschem format
# File format is documented at http://wiki.geda-project.org/geda:file_format_spec
#
class GedaGschemGenerator
  #
  # Constructor
  #
  constructor: (@library) ->
    @f = "%.#{@library.pattern.decimals}f"

  #
  # Generate symbol files
  #
  generate: (@name) ->
    dir = "./gschem/#{@name}/"
    mkdirp.sync "#{dir}"

    # Symbols
    for element in @library.elements
      continue if (not element.symbols?) or 0 == element.symbols.length
      log.start "gEDA gschem symbol '#{element.name}'"
      @_generateSymbol dir, element
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
      min_x = 0
      min_y = 0
      for shape in symbol.shapes
        continue unless shape.x? and shape.y?
        min_x = shape.x if shape.x < min_x
        min_y = shape.y if shape.y < min_y
      symbol.resize(100, true, -min_x, -min_y) # Resize to grid 100 (mil), and translate to 0, 0 (enforce at least this gEDA gschem convention)

      part_name = ""
      if element.symbols.length > 1
        part_name = "_part-#{element.symbols.indexOf(symbol)+1}-#{element.symbols.length}"
        part_name += "-#{symbol.name}" if symbol.name
      fd = fs.openSync "#{dir}/#{element.name}#{part_name}.sym", 'w'
      fs.writeSync fd, "v 20150930 2\n"

      for attribute in ['datasheet', 'keywords', 'aliases']
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
            fs.writeSync fd, "C #{shape.x} #{shape.y} #{shape.radius} 3 0 0 0 -1 -1 0 -1 -1 -1 -1 -1\n"
          when 'arc'
            fs.writeSync fd, "A #{shape.x} #{shape.y} #{shape.radius} #{shape.start} #{shape.end-shape.start} 3 0 0 0 -1 -1\n"
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
            name = shape.name
            if name.includes('~') or shape.inverted
              name = name.replace(/^~/,'').replace(/~$/,'')
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
            fs.writeSync fd, "H 3 0 0 0 -1 -1 0 -1 -1 -1 -1 -1 #{shape.points.length/2}\n"
            for i from [0..(shape.points.length-1)]
               if i % 2 == 0
                 fs.writeSync fd, "#{if i == 0 then M else L} #{shape.points[i]} #{shape.points[i+1]}\n"
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

module.exports = GedaGschemGenerator
