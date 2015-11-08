Qeda = require 'qeda'

lib = new Qeda.Library
lib.add 'Altera/5M1270ZT144' # Adding Altera MAX V CPLD
lib.add 'ST/L3GD20H' # Adding STMicroelectronics gyroscope
lib.add 'TI/ISO721' # Adding Texas Instruments digital isolator
lib.add 'TI/ISO722' # Adding Texas Instruments digital isolator
lib.generate 'mylib'
