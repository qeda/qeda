fs = require 'fs'
mkdirp = require 'mkdirp'
Qeda = require '../src/qeda'

process.chdir __dirname

mkdirp 'library'

dummy = fs.readFileSync '../examples/custom/library/dummy.yaml'
fs.writeFileSync 'library/dummy.yaml', dummy

lib = new Qeda.Library
lib.add 'Dummy'
lib.generate 'qeda_custom'
