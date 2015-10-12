fs = require 'fs'
mkdirp = require 'mkdirp'

class KicadGenerator
  constructor: (@library) ->
    @library.calculateSymbols 'mil'
    @library.calculatePatterns 'mm'

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
      refObj = @_textObj 'refDes', e
      nameObj = @_textObj 'name', e
      fs.writeSync fd, "#\n# #{e.name}\n#\n"
      showPinNumbers = if e.schematics?.showPinNumbers then 'Y' else 'N'
      showPinNames = if e.schematics?.showPinNames then 'Y' else 'N'
      fs.writeSync fd, "DEF #{e.name} #{e.refDes} 0 0 #{showPinNumbers} #{showPinNames} 1 L N\n"
      fs.writeSync fd, "F0 \"#{e.refDes}\" #{refObj.x} #{refObj.y} #{refObj.size} H V #{refObj.halign} #{refObj.valign}NN\n"
      fs.writeSync fd, "F1 \"#{e.name}\" #{nameObj.x} #{nameObj.y} #{nameObj.size} H V #{nameObj.halign} #{nameObj.valign}NN\n"
      fs.writeSync fd, "ENDDEF\n"
    fs.closeSync fd
    console.log "Generating KiCad library '#{name}.lib': OK"

  _textObj: (name, element) ->
    obj = element.symbol.attribute(name) or {}
    obj.x ?= 0
    obj.y ?= 0
    obj.halign = switch obj.halign
      when 'center' then 'C'
      when 'right' then 'R'
      else 'L'
    obj.valign = switch obj.valign
      when 'center' then 'C'
      when 'bottom' then 'B'
      else 'T'
    obj.size = @library.symbol.textSize
    obj

module.exports = KicadGenerator
