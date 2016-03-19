Qeda = require '../src/qeda'

process.chdir __dirname

lib = new Qeda.Library
#lib.add 'Kyocera/145602070001829S'
#lib.add 'Kyocera/245602670001829H+'
lib.add 'Amass/XT60PB'
lib.add 'Harting/09682537613'
lib.generate 'qeda_connector'
