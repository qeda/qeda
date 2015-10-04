Qeda = require '../src/qeda'

lib = new Qeda
lib.add 'TI/ISO721'
lib.add 'TI/ISO722'
lib.generateKicad 'ti_iso'
