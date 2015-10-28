rm = require 'rm-r'
Qeda = require '../src/qeda'

rm.dir './library'

lib = new Qeda.Library
lib.add 'TI/ISO721'
lib.add 'TI/ISO722'
lib.add 'Altera/5M1270ZT144'
