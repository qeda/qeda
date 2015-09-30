rm = require 'rm-r'
Qeda = require '../src/qeda'

rm.file './library/ti/iso721.json'

lib = new Qeda
lib.add 'TI/ISO721'
