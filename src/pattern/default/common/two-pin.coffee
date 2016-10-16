sprintf = require('sprintf-js').sprintf

assembly = require './assembly'
calculator = require './calculator'
copper = require './copper'
courtyard = require './courtyard'
silkscreen = require './silkscreen'

abbrs =
  BEAD: 'bead'
  CAP: 'capacitor'
  DIO: 'diode'
  IND: 'inductor'
  FUS: 'fuse'
  LED: 'led'
  RES: 'resistor'
  VAR: 'varistor'
  XTAL: 'crystal'

getAbbr = (element) ->
  abbr = 'U'
  unless element.keywords? then return abbr
  keywords = element.keywords.toLowerCase().replace(/\s+/g, '').split(',')
  for k, v of abbrs
    if keywords.indexOf(v) isnt -1
      abbr = k
      break
  abbr

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  height = housing.height?.max ? housing.bodyDiameter.max
  abbr = getAbbr element

  if housing.polarized and (abbr isnt 'DIO') and (abbr isnt 'LED') then abbr += 'P'

  if housing.cae # Capacitor Aluminum Electrolytic
    abbr += 'AE'
    option = 'crystal' # CAE is the same as crystal
    size = sprintf "%dX%d",
      [housing.bodyWidth.nom*100
      height*100]
      .map((v) => Math.round v)...
  else if housing.concave
    abbr += 'SC'
    option = 'concave'
    size = sprintf "%02dX%02dX%d",
      [housing.bodyLength.nom*10
      housing.bodyWidth.nom*10
      height*100]
      .map((v) => Math.round v)...
  else if housing.crystal
    option = 'crystal'
    size = sprintf "%02dX%02dX%d",
      [housing.bodyLength.nom*10
      housing.bodyWidth.nom*10
      height*100]
      .map((v) => Math.round v)...
  else if housing.dfn # Dual flat nolead
    abbr += 'DFN'
    option = 'dfn'
    size = sprintf "%02dX%02dX%d",
      [housing.bodyLength.nom*10,
      housing.bodyWidth.nom*10,
      height*100]
      .map((v) => Math.round v)...
  else if housing.molded
    abbr += 'M'
    option = 'molded'
    size = sprintf "%02d%02dX%d",
      [housing.bodyLength.nom*10,
      housing.bodyWidth.nom*10,
      height*100]
      .map((v) => Math.round v)...
  else if housing.melf # Metal Electrode Leadless Face
    abbr += 'MELF'
    option = 'melf'
    size = sprintf "%02d%02d",
      [housing.bodyLength.nom*10,
      housing.bodyDiameter.nom*10]
      .map((v) => Math.round v)...
  else if housing.radial # Radial
    abbr += 'R'
    if housing.diameter
      abbr += 'D'
    option = 'radial'
    size = sprintf "%02dW%02dD%02dH%02d",
      [housing.leadSpan.nom*100,
      housing.leadDiameter.nom*100,
      housing.bodyDiameter.nom*100,
      housing.height.max*100]
      .map((v) => Math.round v)...
  else if housing.sod # Small Outline Diode
    abbr = 'SOD'
    option = 'sod'
    size = sprintf "%02d%02dX%d",
      [housing.leadSpan.nom*10
      housing.bodyWidth.nom*10
      height*100]
      .map((v) => Math.round v)...
  else if housing.sodfl # Small Outline Diode Flat Lead
    abbr = 'SODFL'
    option = 'sodfl'
    size = sprintf "%02d%02dX%d",
      [housing.leadSpan.nom*10
      housing.bodyWidth.nom*10
      height*100]
      .map((v) => Math.round v)...
  else # Chip
    abbr += 'C'
    option = 'chip'
    size = sprintf "%02d%02dX%d",
      [housing.bodyLength.nom*10,
      housing.bodyWidth.nom*10,
      height*100]
      .map((v) => Math.round v)...

  pattern.name ?= sprintf "%s%s%s",
    abbr,
    size,
    settings.densityLevel

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.twoPin pattern, housing, option
  pad =
    shape: 'rectangle'
    x: 0
    y: -padParams.distance/2
    width: padParams.height
    height: padParams.width

  if padParams.hole?
    unless housing.polarized?
      pad.shape = 'circle'
    pad.type = 'through-hole'
    pad.hole = padParams.hole
    pad.layer = ['topCopper', 'topMask', 'topPaste', 'bottomCopper', 'bottomMask', 'bottomPaste']
  else
    pad.type = 'smd'
    pad.layer = ['topCopper', 'topMask', 'topPaste']

  # Copper
  pattern.pad 1, pad
  pad.y = -pad.y
  if pad.hole? then pad.shape = 'circle'
  pattern.pad 2, pad

  copper.mask pattern
  silkscreen.twoPin pattern, housing
  assembly.twoPin pattern, housing
  courtyard.twoPin pattern, housing, padParams.courtyard
