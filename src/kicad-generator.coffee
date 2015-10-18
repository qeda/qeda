fs = require 'fs'
mkdirp = require 'mkdirp'

#
#
#
class KicadGenerator
  constructor: (@library) ->

  #
  #
  #
  generate: (name) ->
    dir = './kikad'
    mkdirp.sync dir
    mkdirp.sync dir + '/' + name

    now = new Date
    timestamp = "#{now.getDate()}/#{now.getMonth() + 1}/#{now.getYear() + 1900} #{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}"
    fd = fs.openSync "#{dir}/#{name}.lib", 'w'
    fs.writeSync fd, "EESchema-LIBRARY Version 2.3 Date: #{timestamp}\n"
    fs.writeSync fd, '#encoding utf-8\n'
    for element in @library.elements
      @_generateSymbol fd, element
    fs.writeSync fd, '# End Library\n'
    fs.closeSync fd
    console.log "Generating KiCad library '#{name}.lib': OK"

  #
  #
  #
  _generateSymbol: (fd, element) ->
    symbol = element.symbol
    symbol.invertVertical() # Positive vertical axis is pointing up in KiCad
    refObj = @_shapeObj symbol.attributes['refDes']
    nameObj = @_shapeObj symbol.attributes['name']
    fs.writeSync fd, "#\n# #{element.name}\n#\n"
    showPinNumbers = if element.schematics?.showPinNumbers then 'Y' else 'N'
    showPinNames = if element.schematics?.showPinNames then 'Y' else 'N'
    pinNameSpace = Math.round @library.symbol.pinNameSpace
    fs.writeSync fd, "DEF #{element.name} #{element.refDes} 0 #{pinNameSpace} #{showPinNumbers} #{showPinNames} 1 L N\n"
    fs.writeSync fd, "F0 \"#{element.refDes}\" #{refObj.x} #{refObj.y} #{refObj.size} H V #{refObj.halign} #{refObj.valign}NN\n"
    fs.writeSync fd, "F1 \"#{element.name}\" #{nameObj.x} #{nameObj.y} #{nameObj.size} H V #{nameObj.halign} #{nameObj.valign}NN\n"
    fs.writeSync fd, "DRAW\n"
    for shape in element.symbol.shapes
      shapeObj = @_shapeObj shape
      switch shapeObj.kind
        when 'pin' then fs.writeSync fd, "X #{shapeObj.name} #{shapeObj.number} #{shapeObj.x} #{shapeObj.y} #{shapeObj.length} #{shapeObj.orientation} #{shapeObj.sizeNum} #{shapeObj.sizeName} 1 1 #{shapeObj.type}#{shapeObj.shape}\n"
        when 'rectangle' then fs.writeSync fd, "S #{shapeObj.x} #{shapeObj.y} #{shapeObj.x + shapeObj.width} #{shapeObj.y + shapeObj.height} 1 1 0 #{shapeObj.fillStyle}\n"
    fs.writeSync fd, "ENDDRAW\n"
    fs.writeSync fd, "ENDDEF\n"

  #
  #
  #
  _shapeObj: (shape) ->
    obj = shape or {}
    obj.x = Math.round obj.x
    obj.y = Math.round obj.y
    obj.length = Math.round obj.length
    if obj.halign?
      obj.halign = switch obj.halign
        when 'center' then 'C'
        when 'right' then 'R'
        else 'L'
    if obj.valign?
      obj.valign = switch obj.valign
        when 'center' then 'C'
        when 'bottom' then 'B'
        else 'T'
    if obj.orientation?
      obj.orientation = switch obj.orientation
        when 'left' then 'L'
        when 'up' then 'U'
        when 'down' then 'D'
        else 'R'
    obj.size = Math.round @library.symbol.textSize
    obj.sizeNum = Math.round @library.symbol.textSize
    obj.sizeName = Math.round @library.symbol.textSize

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
