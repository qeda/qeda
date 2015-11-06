sprintf = require('sprintf-js').sprintf
gullwing = require './common/gullwing'

module.exports = (pattern, housing) ->
  settings = pattern.settings

  pattern.name ?= sprintf "SOP%dP%dX%d-%d",
    [housing.pitch*100
    housing.leadSpan.nom*100
    housing.height.max*100
    housing.leadCount]
    .map((a) => Math.round a)...

  pitch = housing.pitch
  leadCount = housing.leadCount

  # Calculation according to IPC-7351
  dims = gullwing.calculate pattern, housing

  # Trim pads when they extend under body
  defaultShape = 'oval'
  if dims.gap < housing.bodyWidth.nom
    dims.gap = housing.bodyWidth.nom
    defaultShape = 'rectangle'

  # Calculate pad dimensions
  padDims = gullwing.pad dims, pattern
  padWidth = padDims.width
  padHeight = padDims.height
  padDistance = padDims.distance

  pad =
    type: 'smd'
    width: padWidth
    height: padHeight

  pattern.setLayer 'top'

  # Pads on the left side
  pad.x = -padDistance / 2
  y = -pitch * (leadCount/4 - 0.5)
  num = 1
  for i in [1..leadCount/2]
    pad.name = num++
    pad.y = y
    pad.shape =  if i is 1 then 'rectangle' else defaultShape
    pattern.addPad pad
    y += pitch

  # Pads on the right side
  pad.x = padDistance / 2
  y -= pitch
  for i in [(leadCount/2 + 1)..leadCount]
    pad.name = num++
    pad.y = y
    pattern.addPad pad
    y -= pitch

  # Silkscreen
  pattern.setLayer 'topSilkscreen'
  lineWidth = settings.lineWidth.silkscreen
  pattern.setLineWidth lineWidth
  # Rectangle
  rectWidth = housing.bodyWidth.nom
  padSpace = padDistance - padWidth - 2*settings.clearance.padToSilk - lineWidth
  if rectWidth >= padSpace then rectWidth = padSpace
  bodyLength = housing.bodyLength.nom
  pattern.addRectangle { x: -rectWidth/2, y: -bodyLength/2, width: rectWidth, height: bodyLength }
  # First pin keys
  r = 0.25
  x = (-padDistance - padWidth)/2 + r
  y = -pitch*(leadCount/4 - 0.5) - padHeight/2 - r - settings.clearance.padToSilk
  pattern.addCircle { x: x, y: y, radius: r/2, lineWidth: r }
  r = 0.5
  shift = rectWidth/2 - r
  if shift > 0.5 then shift = 0.5
  x = -rectWidth/2 + r + shift
  y = -bodyLength/2 + r + shift
  pattern.addCircle { x: x, y: y, radius: r/2, lineWidth: r }
  # RefDes
  fontSize = settings.fontSize.refDes
  pattern.addAttribute 'refDes',
    x: 0
    y: -bodyLength/2 - fontSize/2 - 2*lineWidth
    halign: 'center'
    valign: 'center'

  # Assembly
  pattern.setLayer 'topAssembly'
  pattern.setLineWidth settings.lineWidth.assembly
  bodyWidth = housing.bodyWidth.nom
  leadLength = (housing.leadSpan.nom - housing.bodyWidth.nom) / 2
  # Body
  pattern.addRectangle { x: -bodyWidth/2, y: -bodyLength/2, width: bodyWidth, height: bodyLength }
  # Leads
  y = -pitch * (leadCount/4 - 0.5)
  for i in [1..leadCount/2]
    pattern.addLine { x1: -bodyWidth/2, y1: y, x2: -bodyWidth/2 - leadLength, y2: y }
    pattern.addLine { x1: bodyWidth/2, y1: y, x2: bodyWidth/2 + leadLength, y2: y }
    y += pitch
  # Key
  r = 0.5
  shift = bodyWidth/2 - r
  if shift > 0.5 then shift = 0.5
  x = -bodyWidth/2 + r + shift
  y = -bodyLength/2 + r + shift
  pattern.addCircle { x: x, y: y, radius: r}
  # Value
  fontSize = settings.fontSize.value
  pattern.addAttribute 'value',
    text: pattern.name
    x: 0
    y: bodyLength/2 + fontSize/2 + 0.5
    halign: 'center'
    valign: 'center'
