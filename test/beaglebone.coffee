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

# Pushbuttons
lib.add 'CK/KMR2'

# Circuits
lib.add 'TI/TPS65217'

# Special
lib.special 'ground', 'MYGND'
lib.special 'power', 'MYVCC'

lib.generate 'qeda_bbb'
