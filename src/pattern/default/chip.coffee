sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
dual = require './common/dual'

abbrs =
  CAP: 'capacitor'
  DIO: 'diode'
  IND: 'inductor'
  LED: 'led'
  RES: 'resistor'

getAbbr = (element) ->
  abbr = 'U'
  unless element.keywords? then return name
  keywords = element.keywords.replace(/\s+/g, '').split(',')
  for k, v of abbrs
    if keywords.indexOf(v) isnt -1
      abbr = k
      break
  abbr

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  height = housing.height.max ? housing.height
  abbr = getAbbr element

  if housing.polarized and (abbr isnt 'DIO') and (abbr isnt 'LED') then abbr += 'P'

  # Calculate pad dimensions according to IPC-7351
  if housing.molded
    abbr += 'M'
    padParams = calculator.molded pattern, housing
  else if housing.melf
    abbr += 'MELF'
    padParams = calculator.melf pattern, housing
  else if housing.nolead
    abbr += 'DFN'
    #padParams = calculator.dfn pattern, housing
  else if housing.cae or housing.crystal
    padParams = calculator.crystal pattern, housing
  else
    abbr += 'C'
    padParams = calculator.chip pattern, housing

  pattern.name ?= sprintf "%s%02d%02dX%d%s",
    abbr,
    [housing.bodyLength.nom*10
    housing.bodyWidth.nom*10
    height*100]
    .map((v) => Math.round v)...,
    settings.densityLevel

  pad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width
    height: padParams.height
    layer: ['topCopper', 'topMask', 'topPaste']
    x: -padParams.distance/2
    y: 0

  # Copper
  pattern.pad 1, pad
  pad.x = -pad.x
  pattern.pad 2, pad

  # Silkscreen
  lineWidth = settings.lineWidth.silkscreen
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom
  leadWidth = housing.leadWidth.nom
  gap = lineWidth/2 + settings.clearance.padToSilk
  x = bodyLength/2 + lineWidth/2
  y1 = padParams.height/2 + gap
  y2 = bodyWidth/2 + lineWidth/2
  y = Math.max y1, y2
  pattern
    .layer 'topSilkscreen'
    .lineWidth lineWidth
    .attribute 'refDes',
      x: 0
      y: 0
      halign: 'center'
      valign: 'center'
  if housing.cae
    d = y2 - y1
    pattern
      .moveTo -x, -y1
      .lineTo -x + d, -y2
      .lineTo x, -y2
      .lineTo x, -y1
      .moveTo -x, y1
      .lineTo -x + d, y2
      .lineTo x, y2
      .lineTo x, y1
  else
    pattern
      .line -x, -y, x, -y
      .line -x, y, x, y

    if y1 < y2 # Molded
      pattern
       .line -x, -y1, -x, -y2
       .line  x, -y1,  x, -y2
       .line -x,  y1, -x,  y2
       .line  x,  y1,  x,  y2

  if housing.polarized or housing.cae
    x2 = padParams.distance/2 + padParams.width/2 + lineWidth/2 + settings.clearance.padToSilk
    pattern
     .moveTo -x, -y1
     .lineTo -x2, -y1
     .lineTo -x2, y1
     .lineTo -x, y1
     .polarityMark -x2 - lineWidth/2, 0

  # Assembly
  x = bodyLength/2
  y = bodyWidth/2
  pattern
    .layer 'topAssembly'
    .lineWidth settings.lineWidth.assembly
    .attribute 'value',
      text: pattern.name
      x: 0
      y: y + settings.fontSize.value/2 + 0.5
      halign: 'center'
      valign: 'center'
      visible: false
  if housing.cae
    d = Math.min bodyWidth/4, bodyLength/4
    pattern
      .moveTo -x, -y + d
      .lineTo -x + d, -y
      .lineTo x, -y
      .lineTo x, y
      .lineTo -x + d, y
      .lineTo -x, y - d
      .lineTo -x, -y + d
  else if housing.polarized
    d = Math.min 1, bodyWidth/2, bodyLength/2
    pattern
      .moveTo -x, -y
      .lineTo x, -y
      .lineTo x, y
      .lineTo -x + d, y
      .lineTo -x, y - d
      .lineTo -x, -y
  else
    pattern.rectangle -x, -y, x, y

  # Courtyard
  courtyard = padParams.courtyard
  x1 = (padParams.width + padParams.distance)/2 + courtyard
  x2 = bodyLength/2 + courtyard
  y1 = padParams.height/2 + courtyard
  y2 = bodyWidth/2 + courtyard
  ym = Math.max y1, y2
  pattern
    .layer 'topCourtyard'
    .lineWidth settings.lineWidth.courtyard
    # Centroid origin marking
    .circle 0, 0, 0.5
    .line -0.7, 0, 0.7, 0
    .line 0, -0.7, 0, 0.7
    # Contour courtyard
    .moveTo -x1, -y1
    .lineTo -x2, -y1
    .lineTo -x2, -ym
    .lineTo x2, -ym
    .lineTo x2, -y1
    .lineTo x1, -y1
    .lineTo x1, y1
    .lineTo x2, y1
    .lineTo x2, ym
    .lineTo -x2, ym
    .lineTo -x2, y1
    .lineTo -x1, y1
    .lineTo -x1, -y1
