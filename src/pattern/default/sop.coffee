sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
dual = require './common/dual'
tab = require './common/tab'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  height = housing.height.max ? housing.height
  leadCount = housing.leadCount
  hasTab = housing.tabWidth? and housing.tabLength?
  if hasTab then ++leadCount
  pattern.name ?= sprintf "SOP%dP%dX%d-%d%s",
    [housing.pitch*100
    housing.leadSpan.nom*100
    height*100
    leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.sop pattern, housing
  padParams.pitch = housing.pitch
  padParams.count = housing.leadCount
  padParams.order = 'round'
  padParams.pad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width
    height: padParams.height
    layer: ['topCopper', 'topMask', 'topPaste']

  dual pattern, padParams
  tab pattern, housing

  firstPad = pattern.pads[1]

  # Silkscreen
  lineWidth = settings.lineWidth.silkscreen
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom
  gap = lineWidth/2 + settings.clearance.padToSilk

  x = bodyWidth/2 + lineWidth/2
  y1 = -bodyLength/2 - lineWidth/2
  y2 = firstPad.y - firstPad.height/2 - gap
  if y1 > y2 then y1 = y2

  pattern
    .layer 'topSilkscreen'
    .lineWidth lineWidth
    .attribute 'refDes',
      x: 0
      y: 0
      halign: 'center'
      valign: 'center'
    .moveTo  x, y2
    .lineTo  x, y1
    .lineTo -x, y1
    .lineTo -x, y2
    .lineTo -x - firstPad.width, y2
    .moveTo  x, -y2
    .lineTo  x, -y1
    .lineTo -x, -y1
    .lineTo -x, -y2
    .polarityMark firstPad.x - firstPad.width/2 - settings.clearance.padToSilk, firstPad.y

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
  x1 = -bodyWidth/2 - courtyard
  y1 = -bodyLength/2 - courtyard
  x2 = firstPad.x - firstPad.width/2 - courtyard
  y2 = firstPad.y - firstPad.height/2 - courtyard
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
    .lineTo -x1, -y2
    .lineTo -x2, -y2
    .lineTo -x2,  y2
    .lineTo -x1,  y2
    .lineTo -x1,  y1
    .lineTo  x1,  y1
