fs = require 'fs'
mkdirp = require 'mkdirp'
sprintf = require('sprintf-js').sprintf

log = require './qeda-log'

#
# Generator of footprint in pcb format
# the pcb format is documented at http://pcb.geda-project.org/pcb-cvs/pcb.html#File-Formats 
#
class PcbGenerator
  #
  # Constructor
  #
  constructor: (@library) ->
    @f = "%.#{@library.pattern.decimals}f"

  #
  # Generate footprint files
  #
  generate: (@name) ->
    dir = "./pcb/#{@name}"
    mkdirp.sync "#{dir}"

    # Footprints
    for element in @library.elements
      next if !element.pattern?
      log.start "pcb footprint '#{element.pattern.name}.fp'"
      fd = fs.openSync "#{dir}/#{element.pattern.name}.fp", 'w'
      @_generatePattern fd, element.pattern
      fs.closeSync fd
      log.ok()

  #
  # Write pattern file
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
          if (shape.type is 'through-hole')
            if (shape.width == shape.height)
              fs.writeSync(fd,
                sprintf("  Pin [#{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm \"\" \"%s\" \"%s\"]\n",
                  shape.x, shape.y, shape.width, shape.clearance, shape.width+2*shape.mask, shape.hole, shape.name, (if shape.shape is 'rectangle' then 'square' else ''))
              )
            else
              width = if shape.width < shape.height then shape.width else shape.height
              fs.writeSync(fd,
                sprintf("  Pin [#{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm #{@f}mm \"\" \"%s\" ""]\n",
                  shape.x, shape.y, width, shape.clearance, width+2*shape.mask, shape.hole, shape.name)
              )
              # let the next section handle drawing the non-square pad
              shape.type = 'smd'
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

    fs.writeSync fd, ")\n" # end of Element

module.exports = PcbGenerator
