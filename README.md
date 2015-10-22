QEDA.js
=======

QEDA.js is a Node.js library aimed to simplify creating libraries of electronic components for using in EDA software. You can easily create both symbols for schematic and land patterns for PCB (conforming to IPC-7351 standard).

Attention
=========

**The project is under active development. Not recommended for use in production.**

Features
========

* Downloading component definitions from global repository
* Generating schematic symbols:
  - Dual-in-line
* Borrowing packages dimensions from standards:
  - JEDEC (partially)
* Land pattern calculation according to IPC-7351:
  - SOP (and SOIC)
* Generating libraries:
  - KiCad format

Installation
============

    npm install qeda

Examples
========

Example below is written on CoffeeScript but one can use vanilla JavaScript.

Generating KiCad library
------------------------

[first.coffee](./examples/first/first.coffee):

```coffeescript
Qeda = require 'qeda'

lib = new Qeda.Library
  symbol:
    units: 'mil'
    gridSize: 50

lib.add 'TI/ISO721' # Adding Texas Instruments ISO721
lib.add 'TI/ISO722' # Adding Texas Instruments ISO722
lib.generateKicad 'ti_iso'
```

This example will download component descriptions from [library repository](https://github.com/qeda/library/) then save them to disk and add to your custom library. Last string is to generate components library in KiCad format (schematic symbols for [Eeschema](http://kicad-pcb.org/discover/eeschema/) as well as PCB footprints for [PcbNew](http://kicad-pcb.org/discover/pcbnew/)).

_API will be documented soon._

Component description
---------------------

Any electronic component is described by JSON file located in `./library` directory (or some subdirectory within). You can clone all available descriptions from <https://github.com/qeda/library>, add your ones, copy from any source. Then just point correspondent path as parameter for `Qeda.Library.add` method (without `./library/` prefix and `.json` suffix).

Description example:

```json
{
  "name": "Dummy",

  "pinout": {
    "DIN":  1,
    "DOUT": 2,
    "Vcc":  [3, 4],
    "GND":  [5, 6],
    "NC":   [7, 8]
  },

  "properties": {
    "power": "Vcc",
    "ground": "GND",
    "in": ["DIN", "Vcc"],
    "out": "DOUT",
    "nc": "NC"
  },

  "schematics": {
    "symbol": "DIL8",
    "showPinNumbers": true,
    "showPinNames": true
  },

  "housing": {
    "pattern": "SOIC127P600X175-8",
    "outline": "JEDEC-MS-012AA"
  }
}
```

_Available JSON fields will be documented soon._


License
=======

Source code is licensed under [MIT license](http://opensource.org/licenses/MIT).

Coming soon
===========

* [ ] Multipart component support
* [ ] Generating schematic symbols:
  - [ ] Quad
  - [ ] GOST
* [ ] Generating libraries:
  - [ ] Eagle XML format
* [ ] SMD land pattern calculation:
  - [ ] BGA
  - [ ] CFP
  - [ ] CGA
  - [ ] CQFP
  - [ ] QFP
  - [ ] Chip
  - [ ] Chip array
  - [ ] Crystal
  - [ ] DFN
  - [ ] LGA
  - [ ] LCC
  - [ ] MELF
  - [ ] Molded body
  - [ ] Oscillator
  - [ ] PLCC
  - [ ] QFN
  - [ ] QFP
  - [ ] SOD
  - [ ] SODFL
  - [ ] SOJ
  - [ ] SON
  - [ ] SOTFL
  - [ ] SOT23
  - [ ] SOT143
  - [ ] SOT223
  - [ ] TO
* [ ] Through-hole land pattern calculation:
  - [ ] Axial lead
  - [ ] DIP
  - [ ] DIL Socket
  - [ ] Mounting holes
  - [ ] Oscillator
  - [ ] PGA
  - [ ] Radial lead
  - [ ] SIP
  - [ ] Test point
  - [ ] TO (Flange mount)
  - [ ] TO (Cylindrical)
  - [ ] Wire
