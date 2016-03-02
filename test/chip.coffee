Qeda = require '../src/qeda'

process.chdir __dirname

lib = new Qeda.Library
lib.add 'Resistor/R0201'
lib.add 'Resistor/R0603'
lib.add 'Resistor/R1206'
lib.add 'Resistor/R2512'
lib.add 'Capacitor/C0603'
lib.add 'Capacitor/CP-A'
lib.add 'Capacitor/CP-D'
lib.add 'Capacitor/CAE-A'
lib.add 'Diode/D-MMU'
lib.add 'Diode/D-MMB'
lib.add 'ECS/CSM-7'
lib.add 'NXP/PMEG3030BEP'
lib.add 'ONSemi/MBRA340T3G'
lib.add 'Vishay/BAT42W'
lib.generate 'qeda_chip'
