crc = require 'crc'
parse = require 'svg-path-parser'

#
# Class for footprint pattern
#
class QedaPattern
  #
  # Constructor
  #
  constructor: (element) ->
    @settings = element.library.pattern
    @crc32 = @_calcCrc element.housing
    @shapes = []
    @currentLayer = ['topCopper']
    @currentLineWidth = 0
    @currentFill = false
    @type = 'smd'
    @attributes = {}
    @pads = []
    @dieLength = element.dieLength || element.dielength || {}
    @x = 0
    @y = 0
    @cx = 0
    @cy = 0
    @chamfer = {}
    _chamfer = element.housing.chamfer
    if typeof _chamfer is 'string'
      _chamfer = @_parseMultiple _chamfer
    _chamfer ?= []
    if _chamfer? and not Array.isArray _chamfer
      _chamfer = [_chamfer]
    for pos in ['TopLeft', 'TopRight', 'BotLeft', 'BotRight']
      @chamfer[pos] = element.housing['chamfer' + pos]
      if typeof @chamfer[pos] is 'string'
        @chamfer[pos] = @_parseMultiple @chamfer[pos]
      @chamfer[pos] ?= [];
      if not Array.isArray @chamfer[pos]
        @chamfer[pos] = [@chamfer[pos]]
      Array::push.apply @chamfer[pos], _chamfer
      @chamfer[pos] = @chamfer[pos].map (a) -> String(a)

  #
  # Add attribute
  #
  attribute: (name, attribute) ->
    attribute.name = name
    attribute.x = @cx + attribute.x
    attribute.y = @cy + attribute.y
    @attributes[name] = @_addShape 'attribute',  attribute
    this

  #
  # Change center point
  #
  center: (x, y) ->
    @cx = x
    @cy = y
    this

  #
  # Add circle
  #
  circle: (x, y, radius) ->
    @_addShape 'circle', { x: @cx + x, y: @cy + y, radius: radius }
    this

  #
  # Return first and last pads
  #
  extremePads: ->
    firstPad = null
    lastPad = null
    for pad in @pads
      firstPad = pad if !firstPad or pad.name < firstPad.name
      lastPad = pad if !lastPad or pad.name > lastPad.name
    [firstPad, lastPad]

  #
  # Set current fill
  #
  fill: (enable) ->
    @_setFill enable
    this

  #
  # Check whether two patterns are equal
  #
  isEqualTo: (pattern) ->
    @crc32 is pattern.crc32

  #
  # Set current layer(s)
  #
  layer: (layer) ->
    unless Array.isArray(layer) then layer = [layer]
    @currentLayer = layer
    this

  #
  # Add line
  #
  line: (x1, y1, x2, y2) ->
    if (x1 isnt x2) or (y1 isnt y2)
      @_addShape 'line', { x1: @cx + x1, y1: @cy + y1, x2: @cx + x2, y2: @cy + y2 }
    this

  #
  # Line to current position
  #
  lineTo: (x, y) ->
    @line @x, @y, x, y
    @moveTo x, y

  #
  # Set current line width
  #
  lineWidth: (lineWidth) ->
    @_setLineWidth lineWidth
    this

  #
  # Change current position
  #
  moveTo: (x, y) ->
    @x = x
    @y = y
    this

  #
  # Add pad
  #
  pad: (name, pad) ->
    pad.name = name
    pad.x = @cx + pad.x
    pad.y = @cy + pad.y
    pad.chamfer = []
    for pos in ['TopLeft', 'TopRight', 'BotLeft', 'BotRight']
      if String(pad.name) in @chamfer[pos]
        pad.chamfer.push pos
    if pad.chamfer.length < 1
      delete pad.chamfer
    if @dieLength? and @dieLength[name]?
      pad.dieLength = @dieLength[name]
    @pads.push(@_addPad pad)
    this

  #
  # Parse array of floats
  #
  parseArray: (input) ->
    unless input? then return [0]
    result = input.toString().replace(/\s+/g, '').split(',').map((v) => parseFloat(v))
    result

  #
  # Parse position point(s)
  #
  parsePosition: (value) ->
    values = value.replace(/\s+/g, '').split(',').map((v) => parseFloat(v))
    points = []
    for x in values by 2
      points.push { x: x }
    values.shift()
    for y, i in values by 2
      points[i/2].y = y
    points

  #
  # Add pad
  #
  path: (d) ->
    parts = parse(d)
    for p in parts
      switch p.code
        when 'l' then @lineTo @x + p.x, @y + p.y
        when 'L' then @lineTo p.x, p.y
        when 'm' then @moveTo @x + p.x, @y + p.y
        when 'M' then @moveTo p.x, p.y
    this

  #
  # Add polarity mark
  #
  polarityMark: (x, y, position = 'left') ->
    d = 0.5
    switch position
      when 'left' then x -= d/2
      when 'right' then x += d/2
      when 'top' then y -= d/2
      when 'bottom' then y += d/2
      when 'topLeft'
        x -= d/2
        y -= d/2
      when 'topRight'
        x += d/2
        y -= d/2
      when 'bottomLeft'
        x -= d/2
        y += d/2
      when 'bottomRight'
        x += d/2
        y += d/2

    switch @settings.polarityMark
      when 'none'
        this
      when 'dot'
        r = d/2
        oldLineWidth = @currentLineWidth
        @lineWidth r
        @circle x, y, r/2
        @lineWidth oldLineWidth

  #
  # Add rectangle
  #
  rectangle: (x1, y1, x2, y2) ->
    if (x1 isnt x2) or (y1 isnt y2)
      @_addShape 'rectangle', { x1: @cx + x1, y1: @cy + y1, x2: @cx + x2, y2: @cy + y2 }
    this

  #
  # Rectangle to current position
  #
  rectangleTo: (x, y) ->
    @rectangle @x, @y, x, y
    @moveTo x, y

  restore: ->
    unless @_origin? then return
    [@x, @y] = @_origin.pop()
    this

  save: ->
    @_origin ?= []
    @_origin.push [@x, @y]
    this

  #
  # Add line which avoid pad overlapping
  #
  silkLine: (x1, y1, x2, y2) ->
    if (x1 isnt x2) or (y1 isnt y2)
      lines = [{ x1: @cx + x1, y1: @cy + y1, x2: @cx + x2, y2: @cy + y2 }]
      for pad in @pads
        newlines = []
        while lines.length
          line = lines.shift()
          parts = @_divideLine(line, pad, @settings.clearance.padToSilk + @settings.lineWidth.silkscreen/2)
          newlines = newlines.concat parts
        lines = newlines
      lines.map (v) => @_addShape 'line', { x1: v.x1, y1: v.y1, x2: v.x2, y2: v.y2 }

    this

  #
  # Add rectangle which avoid pad overlapping
  #
  silkRectangle: (x1, y1, x2, y2) ->
    @silkLine x1, y1, x2, y1
    @silkLine x2, y1, x2, y2
    @silkLine x2, y2, x1, y2
    @silkLine x1, y2, x1, y1

  #
  # Add pad object
  #
  _addPad: (pad) ->
    if pad.type isnt 'smd' and pad.type isnt 'mounting-hole' then @type = 'through-hole'
    @_addShape 'pad', pad

  #
  # Add arbitrary shape object
  #
  _addShape: (kind, shape) ->
    obj =
      kind: kind
    for own prop of shape
      obj[prop] = shape[prop]
    obj.layer ?= @currentLayer
    obj.lineWidth ?= @currentLineWidth
    obj.fill ?= @currentFill
    @shapes.push obj
    obj

  _calcCrc: (housing) ->
    sum = 0
    exclude = ['suffix']
    for key in Object.keys(housing)
      if exclude.indexOf(key) isnt -1 then continue
      sum = crc.crc32 "#{key}=#{housing[key]}", sum
    sum

  _divideLine: (line, pad, space) ->
    px1 = pad.x - pad.width/2 - space
    px2 = pad.x + pad.width/2 + space
    py1 = pad.y - pad.height/2 - space
    py2 = pad.y + pad.height/2 + space
    lines = []
    intersect = false

    # Check whether line is entirely inside the pad
    if (line.x1 >= px1) and (line.x1 <= px2) and
    (line.x2 >= px1) and (line.x2 <= px2) and
    (line.y1 >= py1) and (line.y1 <= py2) and
    (line.y2 >= py1) and (line.y2 <= py2)
      return []

    if line.x1 < line.x2
      left = { x: line.x1, y: line.y1 }
      right = { x: line.x2, y: line.y2 }
    else
      left = { x: line.x2, y: line.y2 }
      right = { x: line.x1, y: line.y1 }

    if left.x < px1 and right.x > px1 # May intersect
      k = (right.y - left.y) / (right.x - left.x)
      y = left.y + k*(px1 - left.x)
      if y > py1 and y < py2 # Intersects
        intersect = true
        lines.push { x1: left.x, y1: left.y, x2: px1, y2: y }

    if left.x < px2 and right.x > px2 # May intersect
      k = (right.y - left.y) / (right.x - left.x)
      y = left.y + k*(px2 - left.x)
      if y > py1 and y < py2 # Intersects
        intersect = true
        lines.push { x1: px2, y1: y, x2: right.x, y2: right.y }

    if line.y1 < line.y2
      top = { x: line.x1, y: line.y1 }
      bottom = { x: line.x2, y: line.y2 }
    else
      top = { x: line.x2, y: line.y2 }
      bottom = { x: line.x1, y: line.y1 }

    if top.y < py1 and bottom.y > py1 # May intersect
      k = (bottom.x - top.x) / (bottom.y - top.y)
      x = top.x + k*(py1 - top.y)
      if x > px1 and x < px2 # Intersects
        intersect = true
        lines.push { x1: top.x, y1: top.y, x2: x, y2: py1 }

    if top.y < py2 and bottom.y > py2 # May intersect
      k = (bottom.x - top.x) / (bottom.y - top.y)
      x = top.x + k*(py2 - top.y)
      if x > px1 and x < px2 # Intersects
        intersect = true
        lines.push { x1: x, y1: py2, x2: bottom.x, y2: bottom.y }

    unless intersect then lines.push line # Return source line

    result = lines.filter (v) => @_lineLength(v) > @settings.lineWidth.silkscreen
    result

  _lineLength: (line) ->
    dx = line.x2 - line.x1
    dy = line.y2- line.y1
    Math.sqrt(dx*dx + dy*dy)

  #
  # Parse pin/group list
  #
  _parseMultiple: (input) ->
    unless input? then return [0]
    result = []
    groups = input.toString().replace(/\s+/g, '').split(',')
    for group in groups
      cap = /(\D*)(\d+)-(\d+)/.exec group
      if cap
        begin = parseInt cap[2]
        end = parseInt cap[3]
        for i in [begin..end]
          result.push cap[1] + i
      else
        result.push group
    result

  #
  # Merge two objects
  #
  _mergeObjects: (dest, src) ->
    for k, v of src
      if typeof v is 'object' and dest.hasOwnProperty k
        @mergeObjects dest[k], v
      else
        dest[k] = v

  #
  # Set current line width
  #
  _setLineWidth: (lineWidth) ->
    @currentLineWidth = lineWidth

  #
  # Set current fill
  #
  _setFill: (enable) ->
    @currentFill = enable

module.exports = QedaPattern
