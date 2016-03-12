Qeda = require '../src/qeda'
ic = require './common/ic'

process.chdir __dirname

lib = new Qeda.Library
ic lib
lib.generate 'qeda_ic'
