Qeda = require 'qeda'

lib = new Qeda.Library
  symbol:
    units: 'mil'
    gridSize: 50

lib.add 'Dummy' # Adding custom element
lib.generateKicad 'dummy'
