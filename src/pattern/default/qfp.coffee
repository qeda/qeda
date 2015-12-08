sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
quad = require './common/quad'

module.exports = (pattern, element) ->
  housing = element.housing
  leadCount = housing.leadCount ? 2*(housing.rowCount + housing.columnCount)
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "QFP%dP%dX%dX%d-%d",
    [housing.pitch*100
    housing.rowSpan.nom*100
    housing.columnSpan.nom*100
    height*100
    leadCount]
    .map((a) => Math.round a)...

  settings = pattern.settings

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.qfp pattern, housing
  padParams.pitch = housing.pitch
  padParams.rowCount = housing.rowCount
  padParams.columnCount = housing.columnCount
  padParams.rowPad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width1
    height: padParams.height1
    distance: padParams.distance1
    layer: ['topCopper', 'topMask', 'topPaste']
  # Rotated to 90 degree (swap width and height)
  padParams.columnPad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.height2
    height: padParams.width2
    distance: padParams.distance2
    layer: ['topCopper', 'topMask', 'topPaste']

  quad pattern, padParams

  firstPad = pattern.pads[1]
  lastPad = pattern.pads[2*(padParams.rowCount + padParams.columnCount)]

  # Silkscreen
  lineWidth = settings.lineWidth.silkscreen
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom

  x = -bodyWidth/2 - lineWidth/2
  y = -bodyLength/2 - lineWidth/2

  x1 = lastPad.x - lastPad.width/2 - lineWidth/2 - settings.clearance.padToSilk
  if x > x1 then x = x1
  y1 = firstPad.y - firstPad.height/2 - lineWidth/2 - settings.clearance.padToSilk
  if y > y1 then y = y1

  pattern
    .layer 'topSilkscreen'
    .lineWidth lineWidth
    .attribute 'refDes',
      x: 0
      y: 0
      halign: 'center'
      valign: 'center'
    .moveTo  x1,  y
    .lineTo  x,   y
    .lineTo  x,   y1
    .lineTo  x - firstPad.width, y1
    .moveTo -x1,  y
    .lineTo -x,   y
    .lineTo -x,   y1
    .moveTo  x1, -y
    .lineTo  x,  -y
    .lineTo  x,  -y1
    .moveTo -x1, -y
    .lineTo -x,  -y
    .lineTo -x,  -y1

  if settings.polarityMark is 'dot'
    r = 0.25
    x = firstPad.x - firstPad.width/2 - r - settings.clearance.padToSilk
    y = firstPad.y
    pattern
      .lineWidth r
      .circle x, y, r/2

  # Assembly
  x = bodyWidth/2
  y = bodyLength/2
  d = 1
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
  x = -bodyWidth/2 - courtyard
  y = -bodyLength/2 - courtyard
  x1 = firstPad.x - firstPad.width/2 - courtyard
  y1 = firstPad.y - firstPad.height/2 - courtyard
  x2 = lastPad.x - lastPad.width/2 - courtyard
  y2 = lastPad.y - lastPad.height/2 - courtyard

  pattern
    .layer 'topCourtyard'
    .lineWidth settings.lineWidth.courtyard
    # Centroid origin marking
    .circle 0, 0, 0.5
    .line -0.7, 0, 0.7, 0
    .line 0, -0.7, 0, 0.7
    # Contour courtyard
    .moveTo  x1,  y1
    .lineTo  x,   y1
    .lineTo  x,   y
    .lineTo  x2,  y
    .lineTo  x2,  y2

    .lineTo -x2,  y2
    .lineTo -x2,  y
    .lineTo -x,   y
    .lineTo -x,   y1
    .lineTo -x1,  y1

    .lineTo -x1, -y1
    .lineTo -x,  -y1
    .lineTo -x,  -y
    .lineTo -x2, -y
    .lineTo -x2, -y2

    .lineTo x2, -y2
    .lineTo x2, -y
    .lineTo x,  -y
    .lineTo x,  -y1
    .lineTo x1, -y1

    .lineTo x1, y1
