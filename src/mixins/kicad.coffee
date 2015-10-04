fs = require 'fs'
mkdirp = require 'mkdirp'

module.exports =
  generateKicad: (name) ->
    dir = './kikad'
    mkdirp.sync dir
    mkdirp.sync dir + '/' + name

    now = new Date
    timestamp = "#{now.getDate()}/#{now.getMonth() + 1}/#{now.getYear() + 1900} #{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}"
    lib = fs.openSync "#{dir}/#{name}.lib", 'w'
    fs.writeSync lib, "EESchema-LIBRARY Version 2.3 Date: #{timestamp}\n"
    fs.writeSync lib, '#encoding utf-8\n'
    for e in @elements
      symbol = e.symbol
      fs.writeSync lib, "#\n# #{e.name}\n#\n"
      showPinNumbers = if e.schematics?.showPinNumbers then 'Y' else 'N'
      showPinNames = if e.schematics?.showPinNames then 'Y' else 'N'
      fs.writeSync lib, "DEF #{e.name} #{e.refDes} 0 0 #{showPinNumbers} #{showPinNames} 1 L N\n"
      fs.writeSync lib, "ENDDEF\n"
    fs.closeSync lib
    console.log "Generating KiCad library '#{name}.lib': OK"
