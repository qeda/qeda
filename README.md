QEDA
====

QEDA is a Node.js library aimed to simplify creating libraries of electronic components for using in EDA software. You can easily create both symbols for schematics (with various styles) and land patterns (conforming to IPC-7351 statdard) for PCB.

Attention
=========

The project is under active development. Not recommended for use.

Examples
========

Examples below are written on CoffeScript but one can use JavaScript.

Generating KiCad library
------------------------

[first.coffee](./examples/first/first.coffee):

```coffeescript
QEDA = require 'QEDA'

lib = new QEDA
lib.add 'ti/iso721'
lib.generateKicad 'ti_iso721'
```

Creating custom element
-----------------------

[library/iso721_custom.json](./examples/second/library/iso721_custom.json):

```json
{
  "name": "ISO721",
  "description": "Single Channel High-Speed Digital Isolator",
  "pins": {
    "Vcc1": [1, 3],
    "IN"  : 2,
    "GND1": 4,
    "OUT" : 6,
    "Vcc2": 8,
    "GND2": [5, 7]
  },

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
QEDA = require 'QEDA'

lib = new QEDA
lib.add 'iso721_custom'
lib.generateKicad 'ti_iso721_custom'
```

License
=======

Source code is licensed under [MIT license](http://opensource.org/licenses/MIT).
