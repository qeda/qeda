Qeda = require '../src/qeda'

process.chdir __dirname

lib = new Qeda.Library
lib.add 'Resistor/R0603'
lib.generate 'qeda_chip'
