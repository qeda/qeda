Qeda = require '../src/qeda'

lib = new Qeda
  symbol:
    units: 'mil'
    gridSize: 50
    
lib.add 'TI/ISO721'
lib.add 'TI/ISO722'
lib.generateKicad 'ti_iso'
