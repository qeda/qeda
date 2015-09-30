fs = require 'fs'
mkdirp = require 'mkdirp'

module.exports =
  generateKicad: (name) ->
    dir = './kikad'
    mkdirp.sync dir
    lib = fs.openSync "#{dir}/#{name}.lib", 'w'
    fs.writeSync lib, 'EESchema-LIBRARY Version 2.3\n'
    fs.writeSync lib, '#encoding utf-8\n'
    for e in @elements
      fs.writeSync lib, "#\n# #{e.name}\n#\n"
      fs.writeSync lib, "DEF #{e.name} #{e.refDes}\n"
    fs.closeSync lib
    console.log "Generating KiCad library '#{name}': OK"
