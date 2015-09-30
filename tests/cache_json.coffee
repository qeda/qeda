rm = require 'rm-r'
qeda = require '../src/qeda'

rm.file './library/ti/iso721.json'

lib = new qeda
lib.add 'TI/ISO721'
