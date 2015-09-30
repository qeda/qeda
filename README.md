QEDA
====

QEDA is a Node.js library aimed to simplify creating libraries of electronic components for using in EDA software. You can easily create both symbols for schematics (with various styles) and land patterns (conforming to IPC-7351 statdard) for PCB.

Attention
=========

The project is under active development. Not recommended for use.

Examples
========

Examples below are written on CoffeeScript but one can use JavaScript.

Generating KiCad library
------------------------

[first.coffee](./examples/first/first.coffee):

```coffeescript
Qeda = require 'qeda'

lib = new Qeda
lib.add 'TI/ISO721' # Adding Texas Instruments' ISO721
lib.add 'TI/ISO722' # Adding Texas Instruments' ISO722
lib.generateKicad 'ti_iso'
```

Creating custom element
-----------------------

[library/iso721-custom.json](./examples/second/library/iso721-custom.json):

```json
{
  "name": "ISO721",
  "description": "Single Channel High-Speed Digital Isolator",

  "pinout": {
    "Vcc1": [1, 3],
    "IN"  : 2,
    "GND1": 4,
    "OUT" : 6,
    "Vcc2": 8,
    "GND2": [5, 7]
  },
  "power": ["Vcc1", "GND1", "Vcc2", "Vcc2"],
  "input": ["IN"],
  "output": ["OUT"],

  "package": ["SOP8", "SOIC8"],
  "SOP8": {
    "ipc": "SOP254P1040X485-8"
  },
  "SOIC8": {
    "ipc": "SOIC127P600X175-8"
  },

  "datasheet": "http://www.ti.com/lit/ds/symlink/iso721.pdf"
}
```

[second.coffee](./examples/second/second.coffee):

```coffeescript
Qeda = require 'qeda'

lib = new Qeda
lib.add 'iso721-custom'
lib.generateKicad 'ti_iso721_custom'
```

License
=======

Source code is licensed under [MIT license](http://opensource.org/licenses/MIT).
