Qeda = require 'qeda'

lib = new Qeda.Library
  symbol:
    units: 'mil'
    gridSize: 50

lib.add 'Altera/5M1270ZT144' # Adding Altera MAX V CPLD
lib.add 'TI/ISO721' # Adding Texas Instruments ISO721
lib.add 'TI/ISO722' # Adding Texas Instruments ISO722
lib.generateKicad 'qeda'
