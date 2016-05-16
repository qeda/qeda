Qeda = require 'qeda'

lib = new Qeda.Library
lib.add 'Altera/5M1270ZT144' # Add Altera MAX V CPLD
lib.add 'Analog/AD9393' # Add Analog Devices HDMI interface
lib.add 'ST/L3GD20H' # Add STMicroelectronics gyroscope
lib.add 'TI/ISO722' # Add Texas Instruments digital isolator
lib.power '+5VDC' # Add power supply symbol
lib.power '+3V3DC' # Add another power supply symbol
lib.ground 'GNDDC' # Add ground symbol
lib.ground 'Signal/GNDS' # Add signal ground symbol
lib.ground 'Earth/GNDE' # Add earth ground symbol
lib.ground 'Chassis/GNDCH' # Add chassis ground symbol
lib.generate 'mylib'
