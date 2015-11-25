sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
quad = require './common/quad'

module.exports = (pattern, element) ->
  housing = element.housing
  leadCount = housing.leadCount ? 2*(housing.rowCount + housing.columnCount)
  if housing.tabWidth? and housing.tabLength then ++leadCount
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "%sQFN%dP%dX%dX%d-%d",
    if housing.pullBack? then 'P' else '',
    [housing.pitch*100
    housing.bodyLength.nom*100
    housing.bodyWidth.nom*100
    height*100
    leadCount]
    .map((a) => Math.round a)...

  settings = pattern.settings

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.qfn pattern, housing
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

  # Silkscreen
  padWidth1 = padParams.width1
  padHeight1 = padParams.height1
  padDistance1 = padParams.distance1
  padWidth2 = padParams.width2
  padHeight2 = padParams.height2
  padDistance2 = padParams.distance2
  pitch = housing.pitch
  rowCount = housing.rowCount
  columnCount = housing.columnCount

  lineWidth = settings.lineWidth.silkscreen
  # Boundary
  x1 = -housing.bodyWidth.nom/2
  x2 = -pitch*(columnCount/2 - 0.5) - padHeight2/2 - lineWidth/2 - settings.clearance.padToSilk
  if x1 > x2 then x1 = x2
  y1 = -housing.bodyLength.nom/2
  y2 = -pitch*(rowCount/2 - 0.5) - padHeight1/2 - lineWidth/2 - settings.clearance.padToSilk
  if y1 > y2 then y1 = y2
  pattern
    .layer 'topSilkscreen'
    .lineWidth lineWidth
    .line  x1,  y1,  x2,  y1
    .line  x1,  y1,  x1,  y2
    .line -x1,  y1, -x2,  y1
    .line -x1,  y1, -x1,  y2
    .line  x1, -y1,  x2, -y1
    .line  x1, -y1,  x1, -y2
    .line -x1, -y1, -x2, -y1
    .line -x1, -y1, -x1, -y2

  # First pin key
  r = 0.25
  x1 = (-padDistance1 - padWidth1)/2 - r - settings.clearance.padToSilk
  x2 = -housing.bodyWidth.nom/2 - r - settings.clearance.padToSilk
  x = Math.min x1, x2
  y = -pitch*(rowCount/2 - 0.5)
  pattern
    .lineWidth r
    .circle x, y, r/2
  # RefDes
  fontSize = settings.fontSize.refDes
  pattern.attribute 'refDes',
    x: 0
    y: -padDistance2/2 - padWidth2/2 - fontSize/2 - 2*lineWidth
    halign: 'center'
    valign: 'center'

  # Assembly
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom
  pattern
    .layer 'topAssembly'
    .lineWidth settings.lineWidth.assembly
    .rectangle -bodyWidth/2, -bodyLength/2, bodyWidth/2, bodyLength/2
  # Key
  r = 0.25
  shift = bodyWidth/2 - r
  if shift > 0.3 then shift = 0.3
  x = -bodyWidth/2 + r + shift
  y = -bodyLength/2 + r + shift
  pattern.circle x, y, r
  # Value
  fontSize = settings.fontSize.value
  pattern.attribute 'value',
    text: pattern.name
    x: 0
    y: bodyLength/2 + fontSize/2 + 0.5
    halign: 'center'
    valign: 'center'
