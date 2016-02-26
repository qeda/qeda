sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
sop = require './sop'
log = require '../../qeda-log'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "SOT%dP%dX%d-%d%s",
    [housing.pitch*100
    housing.leadSpan.nom*100
    height*100
    housing.leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.sot pattern, housing

  pad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width1
    height: padParams.height1
    layer: ['topCopper', 'topMask', 'topPaste']

  # Pads on the left side
  leftCount = housing.leadCount - 1
  pad.x = -padParams.distance / 2
  y = -housing.pitch * (leftCount/2 - 0.5)
  for i in [1..leftCount]
    pad.y = y
    pattern.pad i, pad
    y += housing.pitch

  # Pad on the right side
  pad.x = padParams.distance / 2
  pad.y = 0
  pad.width = padParams.width2
  pad.height = padParams.height2
  pattern.pad leftCount + 1, pad

  firstPad = pattern.pads[1]
  lastPad = pattern.pads[housing.leadCount]

  # Silkscreen
  lineWidth = settings.lineWidth.silkscreen
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom
  gap = lineWidth/2 + settings.clearance.padToSilk

  x = bodyWidth/2 + lineWidth/2
  y1 = -bodyLength/2 - lineWidth/2
  y2 = firstPad.y - firstPad.height/2 - gap
  if y1 > y2 then y1 = y2
  y3 = lastPad.y - lastPad.height/2 - gap

  pattern
    .layer 'topSilkscreen'
    .lineWidth lineWidth
    .attribute 'refDes',
      x: 0
      y: 0
      halign: 'center'
      valign: 'center'
    .moveTo  x, y3
    .lineTo  x, y1
    .lineTo -x, y1
    .lineTo -x, y2
    .lineTo firstPad.x - firstPad.width/2, y2
    .moveTo  x, -y3
    .lineTo  x, -y1
    .lineTo -x, -y1
    .lineTo -x, -y2

  # Assembly
  x = bodyWidth/2
  y = bodyLength/2
  d = Math.min 1, bodyWidth/2, bodyLength/2

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
    .moveTo -x + d, -y
    .lineTo  x, -y
    .lineTo  x,  y
    .lineTo -x,  y
    .lineTo -x, -y + d
    .lineTo -x + d, -y

  # Courtyard
  courtyard = padParams.courtyard
  x1 = -bodyWidth/2 - courtyard
  y1 = -bodyLength/2 - courtyard
  x2 = firstPad.x - firstPad.width/2 - courtyard
  y2 = firstPad.y - firstPad.height/2 - courtyard
  x3 = lastPad.x + lastPad.width/2 + courtyard
  y3 = lastPad.y - lastPad.height/2 - courtyard
  if y1 > y2 then y1 = y2
  pattern
    .layer 'topCourtyard'
    .lineWidth settings.lineWidth.courtyard
    # Centroid origin marking
    .circle 0, 0, 0.5
    .line -0.7, 0, 0.7, 0
    .line 0, -0.7, 0, 0.7
    # Contour courtyard
    .moveTo  x1,  y1
    .lineTo  x1,  y2
    .lineTo  x2,  y2
    .lineTo  x2, -y2
    .lineTo  x1, -y2
    .lineTo  x1, -y2
    .lineTo  x1, -y1
    .lineTo -x1, -y1
    .lineTo -x1, -y3
    .lineTo x3, -y3
    .lineTo x3,  y3
    .lineTo -x1,  y3
    .lineTo -x1,  y1
    .lineTo  x1,  y1
