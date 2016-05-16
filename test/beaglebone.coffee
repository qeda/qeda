Qeda = require '../src/qeda'

process.chdir __dirname

lib = new Qeda.Library

# Resistors
lib.add 'Resistor/R0402'
lib.add 'Resistor/R0603'

# Capacitors
lib.add 'Capacitor/C0402'
lib.add 'Capacitor/C0603'
lib.add 'Capacitor/C0805'

# Inductors
lib.add 'Inductor/L0805'

# Pushbuttons
lib.add 'CK/KMR2'

# Circuits
lib.add 'TI/TPS65217'
#lib.add 'TI/SN74LVC1G07DCK'

# Power supply
lib.power '+5VDC'
lib.ground 'GNDDC'
lib.ground 'signal/GNDS'
lib.ground 'chassis/GNDCH'
lib.ground 'earth/GNDE'

lib.generate 'qeda_bbb'
