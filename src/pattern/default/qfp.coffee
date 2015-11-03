sprintf = require('sprintf-js').sprintf
gullwing = require './common/gullwing'

module.exports = (pattern, housing) ->
  settings = pattern.settings

  pattern.name ?= sprintf "QFP%dP%dX%dX%d-%d",
    [housing.pitch*100
    housing.leadSpan1.nom*100
    housing.leadSpan2.nom*100
    housing.height.max*100
    housing.leadCount]
    .map((a) => Math.round a)...

  pitch = housing.pitch
  leadCount1 = housing.leadCount1
  leadCount2 = housing.leadCount2

  # Calculation according to IPC-7351
  housing.leadSpan = housing.leadSpan1
  dims1 = gullwing.calculate pattern, housing
  housing.leadSpan = housing.leadSpan2
  dims2 = gullwing.calculate pattern, housing

  # Trim pads when they extend under body
  defaultShape = 'oval'
  if dims1.gap < housing.bodyWidth.nom
    dims1.gap = housing.bodyWidth.nom
    defaultShape = 'rectangle'
  if dims2.gap < housing.bodyLength.nom
    dims2.gap = housing.bodyLength.nom
    defaultShape = 'rectangle'

  # Calculate pad dimensions
  padDims1 = gullwing.pad dims1, pattern
  padWidth1 = padDims1.width
  padHeight1 = padDims1.height
  padDistance1 = padDims1.distance

  padDims2 = gullwing.pad dims1, pattern
  padWidth2 = padDims1.width
  padHeight2 = padDims1.height
  padDistance2 = padDims1.distance

  pad1 =
    type: 'smd'
    width: padWidth1
    height: padHeight1

  # Rotated to 90 degree (width and height swapped)
  pad2 =
    type: 'smd'
    width: padHeight2
    height: padWidth2
    shape: defaultShape

  pattern.setLayer 'top'

  # Pads on the left side
  pad1.x = -padDistance1 / 2
  y = -pitch * (leadCount1/2 - 0.5)
  num = 1
  for i in [1..leadCount1]
    pad1.name = num++
    pad1.y = y
    pad1.shape =  if i is 1 then 'rectangle' else defaultShape
    pattern.addPad pad1
    y += pitch

  # Pads on the bottom side
  x = -pitch * (leadCount2/2 - 0.5)
  pad2.y = padDistance2 / 2
  for i in [1..leadCount2]
    pad2.name = num++
    pad2.x = x
    pattern.addPad pad2
    x += pitch

  # Pads on the right side
  pad1.x = padDistance1 / 2
  y -= pitch
  for i in [1..leadCount1]
    pad1.name = num++
    pad1.y = y
    pattern.addPad pad1
    y -= pitch

  # Pads on the top side
  x -= pitch
  pad2.y = -padDistance2 / 2
  for i in [1..leadCount2]
    pad2.name = num++
    pad2.x = x
    pattern.addPad pad2
    x -= pitch

  # Silkscreen
  pattern.setLayer 'topSilkscreen'
  lineWidth = settings.lineWidth.silkscreen
  pattern.setLineWidth lineWidth
  # Rectangle
  rectWidth = housing.bodyWidth.nom
  padSpace1 = padDistance1 - padWidth1 - 2*settings.clearance.padToSilk - lineWidth
  if rectWidth >= padSpace1 then rectWidth = padSpace1
  rectHeight = housing.bodyLength.nom
  padSpace2 = padDistance2 - padWidth2 - 2*settings.clearance.padToSilk - lineWidth
  if rectHeight >= padSpace2 then rectHeight = padSpace2
  pattern.addRectangle { x: -rectWidth/2, y: -rectHeight/2, width: rectWidth, height: rectHeight }
  # First pin keys
  r = 0.25
  x = (-padDistance1 - padWidth1)/2 + r
  y = -pitch*(leadCount1/2 - 0.5) - padHeight1/2 - r - settings.clearance.padToSilk
  pattern.addCircle { x: x, y: y, radius: r/2, lineWidth: r }
  r = 0.5
  shift = rectWidth/2 - r
  if shift > 0.5 then shift = 0.5
  x = -rectWidth/2 + r + shift
  y = -rectHeight/2 + r + shift
  pattern.addCircle { x: x, y: y, radius: r/2, lineWidth: r }
  # RefDes
  fontSize = settings.fontSize.refDes
  pattern.addAttribute 'refDes',
    x: 0
    y: -padDistance2/2 - padWidth2/2 - fontSize/2 - 2*lineWidth
    halign: 'center'
    valign: 'center'

  # Assembly
  pattern.setLayer 'topAssembly'
  pattern.setLineWidth settings.lineWidth.assembly
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom
  leadLength = housing.leadLength.nom
  # Body
  pattern.addRectangle { x: -bodyWidth/2, y: -bodyLength/2, width: bodyWidth, height: bodyLength }
  # Leads
  y = -pitch * (leadCount1/2 - 0.5)
  for i in [1..leadCount1]
    pattern.addLine { x1: -bodyWidth/2, y1: y, x2: -bodyWidth/2 - leadLength, y2: y }
    pattern.addLine { x1: bodyWidth/2,  y1: y, x2: bodyWidth/2 + leadLength,  y2: y }
    y += pitch

  x = -pitch * (leadCount2/2 - 0.5)
  for i in [1..leadCount2]
    pattern.addLine { x1: x, y1: -bodyLength/2, x2: x, y2: -bodyLength/2 - leadLength }
    pattern.addLine { x1: x, y1: bodyLength/2,  x2: x, y2: bodyLength/2 + leadLength }
    x += pitch
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
    y: bodyLength/2 + leadLength + fontSize/2 + 0.5
    halign: 'center'
    valign: 'center'
