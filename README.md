[![NPM version](http://img.shields.io/npm/v/qeda.svg)](https://npmjs.org/package/qeda)
[![Dependencies](https://david-dm.org/qeda/qeda.svg)](https://david-dm.org/qeda/qeda)
[![devDependency Status](https://david-dm.org/qeda/qeda/dev-status.svg)](https://david-dm.org/qeda/qeda#info=devDependencies)

QEDA
====

QEDA is a Node.js library aimed to simplify creating libraries of electronic components for using in EDA software. You can easily create both symbols for schematic and land patterns for PCB.

Attention
=========

**The project is under active development. Not recommended for use in production at the moment.**

Features
========

* Downloading component definitions from global repository
* Generating schematic symbols:
  - Single and multi part IC (dual-in-line, quad)
  - Connectors
  - Capacitors, Resistors, Inductors, Pushbuttons
  - Special symbols (ground, power supply etc.)
  - GOST style alternative
* Borrowing packages dimensions from standards:
  - JEDEC (partially)
* Land pattern calculation according to IPC-7351 (tending to comply latest IPC-7351C):
  - BGA
  - Chip
  - QFN
  - QFP
  - SOP (and SOIC)
* Generating libraries:
  - KiCad format

Installation
============

QEDA module for using in scripts as well as command line interface:

    npm install -g qeda


Examples
========

First example will download component descriptions from [library repository](https://github.com/qeda/library/) then save them to disk and add to library manager. Last string is to generate component library in KiCad format (schematic symbols for [Eeschema](http://kicad-pcb.org/discover/eeschema/) as well as PCB footprints for [PcbNew](http://kicad-pcb.org/discover/pcbnew/)).

CLI
---

Run in terminal (note that component names are case insensitive but power and ground nets are not):

```
qeda add altera/5m1270zt144
qeda add analog/ad9393
qeda add st/l3gd20h
qeda add ti/iso722
qeda power +5VDC
qeda power +3V3DC
qeda ground GNDDC
qeda generate mylib
```
And find generated files in `./kicad` directory.

From script
-----------

Example is written on CoffeeScript but one can use vanilla JavaScript.

[script.coffee](./examples/script/script.coffee):

```coffeescript
Qeda = require 'qeda'

lib = new Qeda.Library
lib.add 'Altera/5M1270ZT144' # Add Altera MAX V CPLD
lib.add 'Analog/AD9393' # Add Analog Devices HDMI interface
lib.add 'ST/L3GD20H' # Add STMicroelectronics gyroscope
lib.add 'TI/ISO722' # Add Texas Instruments digital isolator
lib.power '+5VDC' # Add power supply symbol
lib.power '+3V3DC' # Add another power supply symbol
lib.ground 'GNDDC' # Add ground symbol
lib.generate 'mylib'
```

Run it:

    coffee script.coffee

And find generated files in `./kicad` directory.

_API will be documented soon._

Custom component description
----------------------------

Any electronic component is described using YAML-file located in `./library` directory (or some subdirectory within). You can clone all available descriptions from <https://github.com/qeda/library>, add your ones, copy from any source. Then just point correspondent path as parameter for `qeda add ...` command or `Qeda.Library.add` method (without `./library/` prefix and `.yaml` suffix).

[library/dummy.yaml](./examples/custom/library/dummy.yaml):

```yaml
name: Dummy

pinout:
  DIN: 1
  ~DOUT: 2
  Vcc: 3
  GND: 4, 5
  NC: 6-8

properties:
  power: Vcc
  ground: GND
  in: DIN
  out: ~DOUT
  nc: NC
  inverted: ~DOUT

schematic:
  symbol: IC
  left: DIN, NC
  right: ~DOUT, NC
  top: Vcc
  bottom: GND

housing:
  pattern: SOIC
  outline: JEDEC MS-012 AA
```

_Available YAML fields will be documented soon._

Then run in terminal:

```
qeda add dummy
qeda generate dummy
```
Or create [custom.coffee](./examples/custom/custom.coffee):

```coffeescript
Qeda = require 'qeda'

lib = new Qeda.Library
lib.add 'Dummy' # Adding custom element
lib.generate 'dummy'
```

And run:

    coffee custom.coffee

Result:

![Symbol](./doc/images/dummy.png)
![Footprint](./doc/images/soic.png)

License
=======

Source code is licensed under [MIT license](./LICENSE.md).

Coming soon
===========

* Generating libraries:
  - Eagle XML format
  - DipTrace format
  - gEDA format
* SMD land pattern calculation:
  - CFP
  - CGA
  - CQFP
  - Chip array
  - Crystal
  - DFN
  - LGA
  - LCC
  - MELF
  - Molded body
  - Oscillator
  - PLCC
  - SOD
  - SODFL
  - SOJ
  - SON
  - SOTFL
  - SOT23
  - SOT143
  - SOT223
  - TO
* Through-hole land pattern calculation:
  - Axial lead
  - DIP
  - DIL Socket
  - Mounting holes
  - Oscillator
  - PGA
  - Radial lead
  - SIP
  - Test point
  - TO (Flange mount)
  - TO (Cylindrical)
  - Wire
* 3D models generation
