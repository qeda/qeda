sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
dual = require './common/dual'

module.exports = (pattern, element) ->
  housing = element.housing
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "SOP%dP%dX%d-%d",
    [housing.pitch*100
    housing.leadSpan.nom*100
    height*100
    housing.leadCount]
    .map((a) => Math.round a)...

  settings = pattern.settings

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

  # Silkscreen
  lineWidth = settings.lineWidth.silkscreen
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom
  x = bodyWidth/2 + lineWidth/2
  y1 = -bodyLength/2 - lineWidth/2
  y2 = pattern.pads[1].y - padParams.height - settings.clearance.padToSilk
  if y1 > y2 then y1 = y2
  #fontSize = settings.fontSize.refDes

  pattern
    .layer 'topSilkscreen'
    .lineWidth lineWidth
    .attribute 'refDes',
      x: 0
      y: 0 #-bodyLength/2 - fontSize/2 - 2*lineWidth
      angle: 90
      halign: 'center'
      valign: 'center'
    .moveTo  x, y2
    .lineTo  x, y1
    .lineTo -x, y1
    .lineTo -x, y2
    .lineTo -x - padParams.width, y2
    .moveTo  x, -y2
    .lineTo  x, -y1
    .lineTo -x, -y1
    .lineTo -x, -y2

  if settings.polarityMark is 'dot'
    r = 0.25
    x = pattern.pads[1].x - padParams.width/2 - r - settings.clearance.padToSilk
    y = pattern.pads[1].y
    pattern
      .lineWidth r
      .circle x, y, r/2

  # Assembly
  x = bodyWidth/2
  y = bodyLength/2
  pattern
    .layer 'topAssembly'
    .lineWidth settings.lineWidth.assembly
    .moveTo -x, -y
    .lineTo -1, -y
    .lineTo 0, -y + 1
    .lineTo 1, -y
    .lineTo x, -y
    .lineTo x, y
    .lineTo -x, y
    .lineTo -x, -y
