sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'

module.exports = (pattern, element) ->
  housing = element.housing
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "TO%dP%dX%dX%d-%d",
    [housing.pitch*100
    housing.bodyLength.nom*100
    housing.bodyWidth.nom*100
    height*100
    housing.leadCount]
    .map((v) => Math.round v)...

  settings = pattern.settings

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.d2pak pattern, housing
  pad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width1
    height: padParams.height1
    layer: ['topCopper', 'topMask', 'topPaste']
  #distance = padParams.distance
  pitch = housing.pitch
  leadCount = housing.leadCount
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom
  leadSpan = housing.leadSpan.nom
  tabLedge = housing.tabLedge.nom ? housing.tabLedge
  tabWidth = housing.tabWidth.nom ? housing.tabWidth

  # Pads on the left side
  pad.x = -padParams.distance1/2
  y = -pitch * (leadCount/2 - 0.5)
  for i in [1..leadCount]
    pad.y = y
    pattern.pad i, pad
    y += pitch

  # Tab pad
  pad.width = padParams.width2
  pad.height = padParams.height2
  pad.x = padParams.distance2/2
  pad.y = 0
  pattern.pad leadCount + 1, pad

  # Silkscreen
  lineWidth = settings.lineWidth.silkscreen
  x1 = leadSpan/2 - tabLedge
  x2 = x1 - bodyWidth
  y1 = -bodyLength/2 - lineWidth/2
  y2 = -padParams.height2/2 - lineWidth/2 - settings.clearance.padToSilk
  if y1 > y2 then y1 = y2

  pattern
    .layer 'topSilkscreen'
    .lineWidth lineWidth
    .attribute 'refDes',
      x: 0
      y: 0
      halign: 'center'
      valign: 'center'
    .rectangle x1, y1, x2, -y1

  # Assembly
  x1 = leadSpan/2 - tabLedge
  x2 = x1 - bodyWidth
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
    .rectangle x1, -bodyLength/2, x2, bodyLength/2
    .rectangle x1, -tabWidth/2, x1 + tabLedge, tabWidth/2

  y = -pitch * (leadCount/2 - 0.5)
  for i in [1..leadCount]
    pattern.line -leadSpan/2, y, x2, y
    y += pitch
