Qeda = require '../src/qeda'

lib = new Qeda.Library
  symbol:
    units: 'mil'
    gridSize: 50

lib.add 'Altera/5M1270ZT144'
lib.generateKicad 'altera'
