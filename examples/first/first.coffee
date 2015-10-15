Qeda = require 'qeda'

lib = new Qeda.Library
  symbol:
      units: 'mil'
      gridSize: 50
      
lib.add 'TI/ISO721' # Adding Texas Instruments ISO721
lib.add 'TI/ISO722' # Adding Texas Instruments ISO722
lib.generateKicad 'ti_iso'
