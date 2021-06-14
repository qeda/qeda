fs = require('fs')
mkdirp = require('mkdirp')
sprintf = require('sprintf-js').sprintf
log = require('./qeda-log')
pkg = require('../package.json')

#
# Generator of coralEDA elements
# coralEDA project: http://repo.hu/projects/coraleda/
#
# schematic capture editor: xschem http://repo.hu/projects/xschem/
# symbol file format: http://repo.hu/projects/xschem/xschem_man/developer_info.html
#
# board layout editor: pcb-rnd http://repo.hu/projects/pcb-rnd/
# lihata subcirctuit pattern format: http://repo.hu/projects/pcb-rnd/developer/lihata_format/
#

class CoraledaGenerator
  #
  # Constructor
  #
  constructor: (@library) ->
    @f = "%.#{@library.pattern.decimals}f"

  #
  # Generate element files
  #
  generate: (@name) ->
    # symbols not yet supported

    # output directory for subcircuit (e.g. pattern/footprint)
    dir = "./coraleda/subc/#{@name}/"
    mkdirp.sync("#{dir}")

    # patterns
    for element in @library.elements
      continue if !element.pattern?
      log.start "coralEDA pcb-rnd subcircuit '#{element.pattern.name}.lht'"
      fd = fs.openSync("#{dir}/#{element.pattern.name}.lht", 'w')
      @_generatePattern(fd, element.pattern)
      fs.closeSync(fd)
      log.ok()

  #
  # Remove pin specific attributes to get generic shape
  #
  _toGenericShape: (shape) ->
    generic = JSON.parse(JSON.stringify(shape))
    delete generic.x
    delete generic.y
    delete generic.name
    generic

  #
  # Round pattern dimensions to n places after point
  #
  _RoundPattern: (pattern, n) ->
    for prop in ['x', 'y', 'x1', 'x2', 'y1', 'y2', 'hole', 'width', 'height', 'lineWidth', 'mask']
      for shape in pattern.shapes
        shape[prop] = Number(shape[prop].toFixed(n)) if shape[prop]?
      for pad in pattern.pads
        pattern.pads[pad][prop] = Number(pattern.pads[pad][prop].toFixed(n)) if pattern.pads[pad][prop]?

  #
  # Write pcb-rnd subcircuit pattern file
  #
  _generatePattern: (fd, pattern) ->
    now = new Date
    timestamp = sprintf("%d-%02d-%02d %02d:%02d:%02d", now.getYear() + 1900, now.getMonth() + 1, now.getDate(), now.getHours(), now.getMinutes(), now.getSeconds())
    id = 1 # subc global 32-bits unique identity field
    fs.writeSync(fd, "# subcircuit generated using QEDA\n")
    fs.writeSync(fd, "li:pcb-rnd-subcircuit-v6 {\n")
    fs.writeSync(fd, " ha:subc.#{id++} {\n")
    uid = pattern.name + "........................" # pad
    uid = uid.substring(0, 24) # UID is 24 ASCII char
    fs.writeSync(fd, "  uid = #{uid}\n")
    # write attributes
    fs.writeSync(fd, "  ha:attributes {\n")
    fs.writeSync(fd, "   refdes = #{pattern.attributes.refDes.text}\n") if pattern.attributes.refDes.text?
    fs.writeSync(fd, "   footprint = #{pattern.name}\n")
    fs.writeSync(fd, "  }\n")
    fs.writeSync(fd, "  ha:data {\n")
    # write padstacks
    @_RoundPattern(pattern, 5)
    padstacks = []
    for shape in pattern.shapes
      padstacks.push(@_toGenericShape(shape))
    padstacks = padstacks.map((value) => JSON.stringify(value))
    padstacks = padstacks.filter((value, index, self) => self.indexOf(value) == index)
    padstacks = padstacks.map((value) => JSON.parse(value))
    fs.writeSync(fd, "   li:padstack_prototypes {\n")
    for padstack in padstacks
      continue if padstack.kind != 'pad'
      index = padstacks.indexOf(padstack)
      fs.writeSync(fd, "    ha:ps_proto_v6.#{id + index} {\n")
      fs.writeSync(fd, "     htop = 0\n")
      fs.writeSync(fd, "     hbottom = 0\n")
      if (padstack.type == 'through-hole' or padstack.type == 'mounting-hole')
        if padstack.slotWidth? and padstack.slotHeight?
          fs.writeSync(fd, "     hdia = 0\n")
          if padstack.width > padstack.slotWidth or padstack.height > padstack.slotHeight
            fs.writeSync(fd, "     hplated = 1\n")
          else
            fs.writeSync(fd, "     hplated = 0\n")
        else if padstack.hole?
          fs.writeSync(fd, sprintf("     hdia = #{@f}mm\n", padstack.hole))
          if padstack.width > padstack.hole or padstack.height > padstack.hole
            fs.writeSync(fd, "     hplated = 1\n")
          else
            fs.writeSync(fd, "     hplated = 0\n")
      else
        fs.writeSync(fd, "     hdia = 0\n")
        fs.writeSync(fd, "     hplated = 0\n")
      fs.writeSync(fd, "     li:shape {\n")
      if padstack.slotWidth? and padstack.slotHeight?
        slot_thickness = if padstack.slotWidth > padstack.slotHeight then padstack.slotHeight else padstack.slotWidth
        fs.writeSync(fd, "      ha:ps_shape_v4 {\n")
        fs.writeSync(fd, "       clearance = 0\n")
        fs.writeSync(fd, "       ha:ps_line {\n")
        fs.writeSync(fd, sprintf("        x1 = #{@f}mm\n", padstack.slotWidth / -2 + slot_thickness / 2))
        fs.writeSync(fd, sprintf("        y1 = #{@f}mm\n", padstack.slotHeight / -2 + slot_thickness / 2))
        fs.writeSync(fd, sprintf("        x2 = #{@f}mm\n", padstack.slotWidth / 2 - slot_thickness / 2))
        fs.writeSync(fd, sprintf("        y2 = #{@f}mm\n", padstack.slotHeight / 2 - slot_thickness / 2))
        fs.writeSync(fd, sprintf("        thickness = #{@f}mm\n", slot_thickness))
        fs.writeSync(fd, "        square = 0\n") # 0=round cap; 1=square cap
        fs.writeSync(fd, "       }\n") # end line
        fs.writeSync(fd, "       ha:layer_mask {\n")
        fs.writeSync(fd, "        mech = 1\n")
        fs.writeSync(fd, "       }\n") # end layer_mask
        fs.writeSync(fd, "       ha:combining {\n")
        fs.writeSync(fd, "        auto = 1\n")
        fs.writeSync(fd, "       }\n") # end combining
        fs.writeSync(fd, "      }\n") # end ps_shape_v4
      for layer in padstack.layer
        fs.writeSync(fd, "      ha:ps_shape_v4 {\n")
        if layer.endsWith("Copper")
          fs.writeSync(fd, sprintf("       clearance = #{@f}mm\n", padstack.clearance || pattern.settings.clearance.padToPad || 0))
        else
          fs.writeSync(fd, "       clearance = 0\n")
        switch padstack.shape
          when 'circle'
            if padstack.width == padstack.height
              fs.writeSync(fd, "       ha:ps_circ {\n")
              fs.writeSync(fd, "        x = 0\n")
              fs.writeSync(fd, "        y = 0\n")
              dia = padstack.width
              if layer.endsWith("Mask")
                dia += (padstack.mask || pattern.settings.clearance.padToMask || 0)
              fs.writeSync(fd, sprintf("        dia = #{@f}mm\n", dia))
              fs.writeSync(fd, "       }\n") # end ps_circ
            else # padstack.width != padstack.height
              line_thickness = if padstack.width > padstack.height then padstack.height else padstack.width
              fs.writeSync(fd, "       ha:ps_line {\n")
              if padstack.width > padstack.height
                fs.writeSync(fd, sprintf("        x1 = #{@f}mm\n", padstack.width / -2 + line_thickness / 2))
                fs.writeSync(fd, sprintf("        y1 = #{@f}mm\n", 0))
                fs.writeSync(fd, sprintf("        x2 = #{@f}mm\n", padstack.width / 2 - line_thickness / 2))
                fs.writeSync(fd, sprintf("        y2 = #{@f}mm\n", 0))
              else
                fs.writeSync(fd, sprintf("        x1 = #{@f}mm\n", 0))
                fs.writeSync(fd, sprintf("        y1 = #{@f}mm\n", padstack.height / -2 + line_thickness / 2))
                fs.writeSync(fd, sprintf("        x2 = #{@f}mm\n", 0))
                fs.writeSync(fd, sprintf("        y2 = #{@f}mm\n", padstack.height / 2 - line_thickness / 2))
              mask = if layer.endsWith("Mask") then (padstack.mask || pattern.settings.clearance.padToMask || 0) else 0
              fs.writeSync(fd, sprintf("        thickness = #{@f}mm\n", line_thickness + mask * 2))
              fs.writeSync(fd, "        square = 0\n") # 0=round cap; 1=square cap
              fs.writeSync(fd, "       }\n") # end line
          when 'rectangle'
            width = padstack.width
            height = padstack.height
            if layer.endsWith("Mask")
              width += 2 * (padstack.mask || pattern.settings.clearance.padToMask || 0)
              height += 2 * (padstack.mask || pattern.settings.clearance.padToMask || 0)
            if pattern.settings.smoothPadCorners
              corner = if width < height then width else height
              corner *= pattern.settings.ratio.cornerToWidth
              if corner > pattern.settings.maximum.cornerRadius
                corner = pattern.settings.maximum.cornerRadius
              angle_step = 10
              # draw rounded rectangle using line approximation (arcs are not possible in polygons)
              fs.writeSync(fd, "       li:ps_poly {\n")
              # top right corner
              for angle in [0..90] by angle_step
                angle_x = Math.cos(Math.PI * 2 / 360 * angle) * corner
                angle_y = Math.sin(Math.PI * 2 / 360 * angle) * corner
                fs.writeSync(fd, sprintf("        #{@f}mm\n", width / 2 - corner + angle_x))
                fs.writeSync(fd, sprintf("        #{@f}mm\n", height / -2 + corner - angle_y))
              # top left corner
              for angle in [90..180] by angle_step
                angle_x = Math.cos(Math.PI * 2 / 360 * angle) * corner
                angle_y = Math.sin(Math.PI * 2 / 360 * angle) * corner
                fs.writeSync(fd, sprintf("        #{@f}mm\n", width / -2 + corner + angle_x))
                fs.writeSync(fd, sprintf("        #{@f}mm\n", height / -2 + corner - angle_y))
              # bottom left corner
              for angle in [180..270] by angle_step
                angle_x = Math.cos(Math.PI * 2 / 360 * angle) * corner
                angle_y = Math.sin(Math.PI * 2 / 360 * angle) * corner
                fs.writeSync(fd, sprintf("        #{@f}mm\n", width / -2 + corner + angle_x))
                fs.writeSync(fd, sprintf("        #{@f}mm\n", height / 2 - corner - angle_y))
              # bottom right corner
              for angle in [270..360] by angle_step
                angle_x = Math.cos(Math.PI * 2 / 360 * angle) * corner
                angle_y = Math.sin(Math.PI * 2 / 360 * angle) * corner
                fs.writeSync(fd, sprintf("        #{@f}mm\n", width / 2 - corner + angle_x))
                fs.writeSync(fd, sprintf("        #{@f}mm\n", height / 2 - corner - angle_y))
              fs.writeSync(fd, "       }\n") # end ps_poly
            else
              fs.writeSync(fd, "       li:ps_poly {\n")
              fs.writeSync(fd, sprintf("        #{@f}mm\n", width / -2))
              fs.writeSync(fd, sprintf("        #{@f}mm\n", height / -2))
              fs.writeSync(fd, sprintf("        #{@f}mm\n", width / 2))
              fs.writeSync(fd, sprintf("        #{@f}mm\n", height / -2))
              fs.writeSync(fd, sprintf("        #{@f}mm\n", width / 2))
              fs.writeSync(fd, sprintf("        #{@f}mm\n", height / 2))
              fs.writeSync(fd, sprintf("        #{@f}mm\n", width / -2))
              fs.writeSync(fd, sprintf("        #{@f}mm\n", height / 2))
              fs.writeSync(fd, "       }\n") # end ps_poly
        fs.writeSync(fd, "       ha:layer_mask {\n")
        if layer.startsWith("top")
          fs.writeSync(fd, "        top = 1\n")
        else if layer.startsWith("bottom")
          fs.writeSync(fd, "        bottom = 1\n")
        else if layer.startsWith("int")
          fs.writeSync(fd, "        intern = 1\n")
        if layer.endsWith("Copper")
          fs.writeSync(fd, "        copper = 1\n")
        else if layer.endsWith("Mask")
          fs.writeSync(fd, "        mask = 1\n")
        else if layer.endsWith("Paste")
          fs.writeSync(fd, "        paste = 1\n")
        fs.writeSync(fd, "       }\n") # end layer_mask
        fs.writeSync(fd, "       ha:combining {\n")
        if layer.endsWith("Mask")
          fs.writeSync(fd, "        sub = 1\n")
          fs.writeSync(fd, "        auto = 1\n")
        else if layer.endsWith("Paste")
          fs.writeSync(fd, "        auto = 1\n")
        fs.writeSync(fd, "       }\n") # end combining
        fs.writeSync(fd, "      }\n") # end ps_shape_v4
      fs.writeSync(fd, "     }\n") # end shape
      fs.writeSync(fd, "    }\n") # end ps_proto_v6
    fs.writeSync(fd, "   }\n") # end padstack_prototypes
    id += padstacks.length
    # write pads
    fs.writeSync(fd, "   li:objects {\n")
    for shape in pattern.shapes
      continue if shape.kind != 'pad'
      fs.writeSync(fd, "    ha:padstack_ref.#{id++} {\n")
      padstack = padstacks.map((value) => JSON.stringify(value)).indexOf(JSON.stringify(@_toGenericShape(shape)))
      continue if padstack < 0
      fs.writeSync(fd, "     proto = #{padstack + 2}\n")
      fs.writeSync(fd, "     rot = 0\n")
      fs.writeSync(fd, sprintf("     x = #{@f}mm\n", shape.x))
      fs.writeSync(fd, sprintf("     y = #{@f}mm\n", shape.y))
      fs.writeSync(fd, "     ha:attributes {\n")
      fs.writeSync(fd, "      term = #{shape.name}\n")
      fs.writeSync(fd, "      name = #{shape.name}\n")
      fs.writeSync(fd, "     }\n") # end attributes
      fs.writeSync(fd, sprintf("     clearance = #{@f}mm\n", padstack.clearance || pattern.settings.clearance.padToPad || 0))
      fs.writeSync(fd, "     ha:flags {\n")
      fs.writeSync(fd, "      clearline = 1\n")
      fs.writeSync(fd, "     }\n") # end attributes
      fs.writeSync(fd, "    }\n") # end padstack_ref
    fs.writeSync(fd, "   }\n") # end objects
    # write lines in layers
    fs.writeSync(fd, "   li:layers {\n")
    lid = 0 # layer ID
    # subc-aux is a special layer to define the origin/scale/rotation
    fs.writeSync(fd, "    ha:subc-aux {\n")
    fs.writeSync(fd, "     lid = #{lid++}\n")
    fs.writeSync(fd, "     ha:type {\n")
    fs.writeSync(fd, "      top = 1\n")
    fs.writeSync(fd, "      misc = 1\n")
    fs.writeSync(fd, "      virtual = 1\n")
    fs.writeSync(fd, "     }\n")
    fs.writeSync(fd, "     li:objects {\n")
    # define new origin as the one use for the pins
    x_origin = pattern.box.x
    y_origin = pattern.box.y * -1
    # origin
    fs.writeSync(fd, "      ha:line.#{id++} {\n")
    fs.writeSync(fd, "       clearance = 0\n")
    fs.writeSync(fd, "       thickness = 0.1mm\n")
    fs.writeSync(fd, "       ha:attributes {\n")
    fs.writeSync(fd, "        subc-role = origin\n")
    fs.writeSync(fd, "       }\n") # end attributes
    fs.writeSync(fd, sprintf("       x1 = #{@f}mm\n", x_origin))
    fs.writeSync(fd, sprintf("       x2 = #{@f}mm\n", x_origin))
    fs.writeSync(fd, sprintf("       y1 = #{@f}mm\n", y_origin))
    fs.writeSync(fd, sprintf("       y2 = #{@f}mm\n", y_origin))
    fs.writeSync(fd, "      }\n") # end line
    # x-axis
    fs.writeSync(fd, "      ha:line.#{id++} {\n")
    fs.writeSync(fd, "       clearance = 0\n")
    fs.writeSync(fd, "       thickness = 0.1mm\n")
    fs.writeSync(fd, "       ha:attributes {\n")
    fs.writeSync(fd, "        subc-role = x\n")
    fs.writeSync(fd, "       }\n") # end attributes
    fs.writeSync(fd, sprintf("       x1 = #{@f}mm\n", x_origin))
    fs.writeSync(fd, sprintf("       x2 = #{@f}mm\n", x_origin + 1.0))
    fs.writeSync(fd, sprintf("       y1 = #{@f}mm\n", y_origin))
    fs.writeSync(fd, sprintf("       y2 = #{@f}mm\n", y_origin))
    fs.writeSync(fd, "      }\n") # end line
    # y-axis
    fs.writeSync(fd, "      ha:line.#{id++} {\n")
    fs.writeSync(fd, "       clearance = 0\n")
    fs.writeSync(fd, "       thickness = 0.1mm\n")
    fs.writeSync(fd, "       ha:attributes {\n")
    fs.writeSync(fd, "        subc-role = y\n")
    fs.writeSync(fd, "       }\n") # end attributes
    fs.writeSync(fd, sprintf("       x1 = #{@f}mm\n", x_origin))
    fs.writeSync(fd, sprintf("       x2 = #{@f}mm\n", x_origin))
    fs.writeSync(fd, sprintf("       y1 = #{@f}mm\n", y_origin))
    fs.writeSync(fd, sprintf("       y2 = #{@f}mm\n", y_origin + 1.0))
    fs.writeSync(fd, "      }\n") # end line
    fs.writeSync(fd, "     }\n") # end objects
    fs.writeSync(fd, "    }\n") # end subc-aux
    for side in ['top'] # bottom is not used AFAIK
      for type in ['Silkscreen', 'Assembly', 'Courtyard']
        fs.writeSync(fd, "    ha:#{side}-#{type.toLowerCase()} {\n")
        fs.writeSync(fd, "     lid = #{lid}\n")
        fs.writeSync(fd, "     ha:type {\n")
        fs.writeSync(fd, "      #{side} = 1\n")
        switch type
          when 'Silkscreen'
            fs.writeSync(fd, "      silk = 1\n")
          when 'Assembly'
            fs.writeSync(fd, "      doc = 1\n")
          when 'Courtyard'
            fs.writeSync(fd, "      doc = 1\n")
        fs.writeSync(fd, "     }\n") # end type
        switch type
          when 'Assembly'
            fs.writeSync(fd, "     purpose = assy\n")
          when 'Courtyard'
            fs.writeSync(fd, "     purpose = ko.courtyard\n")
        fs.writeSync(fd, "     li:objects {\n")
        for shape in pattern.shapes
          continue if !shape.layer.includes(side+type)
          continue if shape.visible? and !shape.visible
          switch shape.kind
            when 'line'
              fs.writeSync(fd, "      ha:line.#{id++} {\n")
              fs.writeSync(fd, sprintf("       x1 = #{@f}mm\n", shape.x1))
              fs.writeSync(fd, sprintf("       y1 = #{@f}mm\n", shape.y1))
              fs.writeSync(fd, sprintf("       x2 = #{@f}mm\n", shape.x2))
              fs.writeSync(fd, sprintf("       y2 = #{@f}mm\n", shape.y2))
              fs.writeSync(fd, sprintf("       thickness = #{@f}mm\n", shape.lineWidth || pattern.settings.lineWidth[type.toLowerCase()]))
              fs.writeSync(fd, "       clearance = 0\n")
              fs.writeSync(fd, "      }\n") # end line
            when 'circle'
              fs.writeSync(fd, "      ha:arc.#{id++} {\n")
              fs.writeSync(fd, sprintf("       x = #{@f}mm\n", shape.x))
              fs.writeSync(fd, sprintf("       y = #{@f}mm\n", shape.y))
              fs.writeSync(fd, sprintf("       width = #{@f}mm\n", shape.radius))
              fs.writeSync(fd, sprintf("       height = #{@f}mm\n", shape.radius))
              fs.writeSync(fd, sprintf("       thickness = #{@f}mm\n", shape.lineWidth || pattern.settings.lineWidth[type.toLowerCase()]))
              fs.writeSync(fd, "       astart = 0\n")
              fs.writeSync(fd, "       adelta = 360\n")
              fs.writeSync(fd, "       clearance = 0\n")
              fs.writeSync(fd, "      }\n") # end arc
            when 'attribute'
              fs.writeSync(fd, "      ha:text.#{id++} {\n")
              fs.writeSync(fd, sprintf("       x = #{@f}mm\n", shape.x))
              fs.writeSync(fd, sprintf("       y = #{@f}mm\n", shape.y))
              if shape.angle?
                fs.writeSync(fd, "       rot = #{shape.angle}\n")
              else
                fs.writeSync(fd, "       rot = 0\n")
              if shape.fontSize?
                fs.writeSync(fd, "       scale = #{Math.round(shape.fontSize * 100)}\n")
              else
                fs.writeSync(fd, "       scale = 100\n")
              if shape.name == 'refDes'
                fs.writeSync(fd, "       string = %a.parent.refdes%\n")
              else if shape.text?
                fs.writeSync(fd, "       string = #{shape.text}\n")
              fs.writeSync(fd, "       fid = 0\n")
              fs.writeSync(fd, "       ha:flags {\n")
              fs.writeSync(fd, "         floater = 1\n")
              fs.writeSync(fd, "         dyntext = 1\n") if shape.name == 'refDes'
              fs.writeSync(fd, "       }\n") # end flags
              fs.writeSync(fd, "      }\n") # end text
        fs.writeSync(fd, "     }\n") # end objects
        fs.writeSync(fd, "    }\n") # end layer
        lid += 1
    fs.writeSync(fd, "   }\n") # end layers
    # close
    fs.writeSync(fd, "  }\n") # end of data
    fs.writeSync(fd, " }\n") # end of subc
    fs.writeSync(fd, "}\n") # end of pcb-rnd-subcircuit-v6

module.exports = CoraledaGenerator
