Qeda = require '../src/qeda'

lib = new Qeda.Library
  symbol:
    units: 'mil'
    gridSize: 50

lib.add 'Dummy'
lib.generateKicad 'dummy'
