Qeda = require '../src/qeda'

lib = new Qeda.Library
lib.add 'Altera/5M1270ZT144'
lib.add 'TI/ISO721'
lib.add 'TI/ISO722'
lib.generate 'qeda'
