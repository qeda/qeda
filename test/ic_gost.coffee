Qeda = require '../src/qeda'

process.chdir __dirname

lib = new Qeda.Library
  symbol:
    style: 'GOST'

lib.add 'Altera/5M1270ZT144'
lib.add 'Analog/AD9393'
lib.add 'ST/L3GD20H'
lib.add 'TI/ISO721'
lib.add 'TI/ISO722'
lib.generate 'qeda_gost'
