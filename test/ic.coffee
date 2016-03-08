Qeda = require '../src/qeda'

process.chdir __dirname

lib = new Qeda.Library
lib.add 'Analog/AD9393'
lib.add 'Atmel/ATA6670'
lib.add 'Atmel/ATtiny25'
lib.add 'IRF/AUIRFS8409-7P'
lib.add 'IRF/IRFL014N'
lib.add 'Maxim/MAX6421'
lib.add 'Micrel/MIC29301'
lib.add 'ONSemi/MMBT3904L'
lib.add 'ST/L3GD20H'
lib.add 'TI/INA169'
lib.add 'TI/ISO721'
lib.add 'TI/ISO722'
lib.add 'TI/LM258'
lib.add 'TI/LM2596'
lib.add 'TI/LM2940'
lib.add 'TI/LM5050-2'
lib.add 'TI/TLV710'
lib.generate 'qeda_ic'
