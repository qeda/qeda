Qeda = require 'qeda'

lib = new Qeda.Library
lib.add 'Altera/5M1270ZT144' # Add Altera MAX V CPLD
lib.add 'Analog/AD9393' # Add Analog Devices HDMI interface
lib.add 'ST/L3GD20H' # Add STMicroelectronics gyroscope
lib.add 'TI/ISO721' # Add Texas Instruments digital isolator
lib.add 'TI/ISO722' # Add Texas Instruments digital isolator
lib.generate 'mylib'
