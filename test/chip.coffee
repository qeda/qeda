Qeda = require '../src/qeda'

process.chdir __dirname

lib = new Qeda.Library
lib.add 'Resistor/R0201'
lib.add 'Resistor/R0603'
lib.add 'Resistor/R1206'
lib.add 'Resistor/R2512'
lib.generate 'qeda_chip'
