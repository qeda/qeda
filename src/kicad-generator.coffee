fs = require 'fs'
mkdirp = require 'mkdirp'

class KicadGenerator
  constructor: (@library) ->

  generate: (name) ->
    dir = './kikad'
    mkdirp.sync dir
    mkdirp.sync dir + '/' + name

    now = new Date
    timestamp = "#{now.getDate()}/#{now.getMonth() + 1}/#{now.getYear() + 1900} #{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}"
    fd = fs.openSync "#{dir}/#{name}.lib", 'w'
    fs.writeSync fd, "EESchema-LIBRARY Version 2.3 Date: #{timestamp}\n"
    fs.writeSync fd, '#encoding utf-8\n'
    for e in @library.elements
      symbol = e.symbol
      symbol.invertVertical() # Positive vertical axis is pointing up in KiCad
      refObj = @_shapeObj symbol.attribute('refDes')
      nameObj = @_shapeObj symbol.attribute('name')
      fs.writeSync fd, "#\n# #{e.name}\n#\n"
      showPinNumbers = if e.schematics?.showPinNumbers then 'Y' else 'N'
      showPinNames = if e.schematics?.showPinNames then 'Y' else 'N'
      pinNameSpace = Math.round @library.symbol.pinNameSpace
      fs.writeSync fd, "DEF #{e.name} #{e.refDes} 0 #{pinNameSpace} #{showPinNumbers} #{showPinNames} 1 L N\n"
      fs.writeSync fd, "F0 \"#{e.refDes}\" #{refObj.x} #{refObj.y} #{refObj.size} H V #{refObj.halign} #{refObj.valign}NN\n"
      fs.writeSync fd, "F1 \"#{e.name}\" #{nameObj.x} #{nameObj.y} #{nameObj.size} H V #{nameObj.halign} #{nameObj.valign}NN\n"
      fs.writeSync fd, "DRAW\n"
      for shape in e.symbol.shapes
        shapeObj = @_shapeObj shape
        switch shapeObj.type
          when 'pin' then fs.writeSync fd, "X #{shapeObj.name} #{shapeObj.number} #{shapeObj.x} #{shapeObj.y} #{shapeObj.length} #{shapeObj.orientation} #{shapeObj.sizeNum} #{shapeObj.sizeName} 1 1 U\n"
          when 'rectangle' then fs.writeSync fd, "S #{shapeObj.x} #{shapeObj.y} #{shapeObj.x + shapeObj.width} #{shapeObj.y + shapeObj.height} 1 1 0 N\n"
      fs.writeSync fd, "ENDDRAW\n"
      fs.writeSync fd, "ENDDEF\n"
    fs.closeSync fd
    console.log "Generating KiCad library '#{name}.lib': OK"

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
    obj

module.exports = KicadGenerator
