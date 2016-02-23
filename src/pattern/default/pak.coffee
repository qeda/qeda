sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "TO%dP%dX%dX%d-%d%s",
    [housing.pitch*100
    housing.bodyLength.nom*100
    housing.bodyWidth.nom*100
    height*100
    housing.leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.pak pattern, housing
  pad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width1
    height: padParams.height1
    layer: ['topCopper', 'topMask', 'topPaste']
  pitch = housing.pitch
  leadCount = housing.leadCount
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom
  leadSpan = housing.leadSpan.nom
  tabLedge = housing.tabLedge.nom ? housing.tabLedge
  tabWidth = housing.tabWidth.nom ? housing.tabWidth

  pins = element.pins
  # Pads on the left side
  pad.x = -padParams.distance1/2
  y = -pitch * (leadCount/2 - 0.5)
  for i in [1..leadCount]
    pad.y = y
    if pins[i]? then pattern.pad i, pad # Add only if exists
    y += pitch


  # Tab pad
  pad.width = padParams.width2
  pad.height = padParams.height2
  pad.x = padParams.distance2/2
  pad.y = 0
  pattern.pad leadCount + 1, pad

  firstPad = pattern.pads[1]
  lastPad = pattern.pads[leadCount + 1]

  # Silkscreen
  lineWidth = settings.lineWidth.silkscreen
  gap = lineWidth/2 + settings.clearance.padToSilk

  x1 = firstPad.x - firstPad.width/2
  x3 = lastPad.x - lastPad.width/2 - gap
  x4 = leadSpan/2 - tabLedge
  x2 = x4 - bodyWidth - lineWidth/2
  y1 = firstPad.y - firstPad.height/2 - gap
  y2 = -bodyLength/2 - lineWidth/2
  y3 = lastPad.y - lastPad.height/2 - gap
  ym = Math.min y2, y3

  pattern
    .layer 'topSilkscreen'
    .lineWidth lineWidth
    .attribute 'refDes',
      x: 0
      y: 0
      halign: 'center'
      valign: 'center'
    .moveTo x1, y1
    .lineTo x2, y1
    .lineTo x2, y2
    .lineTo x3, y2
    .lineTo x3, ym
    .lineTo x4, ym
    .lineTo x4, y3
    .moveTo x2, -y1
    .lineTo x2, -y2
    .lineTo x3, -y2
    .lineTo x3, -ym
    .lineTo x4, -ym
    .lineTo x4, -y3

  # Assembly
  x1 = leadSpan/2 - tabLedge
  x2 = x1 - bodyWidth
  pattern
    .layer 'topAssembly'
    .lineWidth settings.lineWidth.assembly
    .attribute 'value',
      text: pattern.name
      x: 0
      y: bodyLength/2 + settings.fontSize.value/2 + 0.5
      halign: 'center'
      valign: 'center'
      visible: false
    .rectangle x1, -bodyLength/2, x2, bodyLength/2
    .rectangle x1, -tabWidth/2, x1 + tabLedge, tabWidth/2

  y = -pitch * (leadCount/2 - 0.5)
  for i in [1..leadCount]
    if pins[i]? then pattern.line -leadSpan/2, y, x2, y
    y += pitch

  # Courtyard
  courtyard = padParams.courtyard
  x1 = firstPad.x - firstPad.width/2 - courtyard
  x2 = leadSpan/2 - tabLedge - bodyWidth - courtyard
  x3 = lastPad.x - lastPad.width/2 - courtyard
  x4 = leadSpan/2 - tabLedge + courtyard
  x5 = lastPad.x + lastPad.width/2 + courtyard
  y1 = firstPad.y - firstPad.height/2 - courtyard
  y2 = -bodyLength/2 - lineWidth/2 - courtyard
  y3 = lastPad.y - lastPad.height/2 - lineWidth/2 - settings.clearance.padToSilk
  ym = Math.min y2, y3

  pattern
    .layer 'topCourtyard'
    .lineWidth settings.lineWidth.courtyard
    # Centroid origin marking
    .circle 0, 0, 0.5
    .line -0.7, 0, 0.7, 0
    .line 0, -0.7, 0, 0.7
    # Contour courtyard
    .moveTo x1, y1
    .lineTo x2, y1
    .lineTo x2, y2
    .lineTo x3, y2
    .lineTo x3, ym
    .lineTo x4, ym
    .lineTo x4, y3
    .lineTo x5, y3
    .lineTo x5, -y3
    .lineTo x4, -y3
    .lineTo x4, -ym
    .lineTo x3, -ym
    .lineTo x3, -y2
    .lineTo x2, -y2
    .lineTo x2, -y1
    .lineTo x1, -y1
    .lineTo x1, y1
