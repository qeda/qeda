rm = require 'rm-r'
Qeda = require '../src/qeda'

rm.file './library/ti/iso72x.json'
rm.file './library/ti/iso721.json'
rm.file './library/ti/iso722.json'

lib = new Qeda.Library
lib.add 'TI/ISO721'
lib.add 'TI/ISO722'
