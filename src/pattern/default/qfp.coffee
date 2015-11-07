sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
quad = require './common/quad'

module.exports = (pattern, housing) ->
  pattern.name ?= sprintf "QFP%dP%dX%dX%d-%d",
    [housing.pitch*100
    housing.leadSpan1.nom*100
    housing.leadSpan2.nom*100
    housing.height*100
    housing.leadCount]
    .map((a) => Math.round a)...

  settings = pattern.settings


  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.qfp pattern, housing
  padParams.defaultShape = if padParams.trimmed then 'rectangle' else 'oval'
  padParams.pitch = housing.pitch
  padParams.count1 = housing.leadCount1
  padParams.count2 = housing.leadCount2

  pattern.setLayer 'top'
  quad pattern, padParams

  # Silkscreen
  padWidth1 = padParams.width1
  padHeight1 = padParams.height1
  padDistance1 = padParams.distance1
  padWidth2 = padParams.width2
  padHeight2 = padParams.height2
  padDistance2 = padParams.distance2
  pitch = housing.pitch
  leadCount1 = housing.leadCount1
  leadCount2 = housing.leadCount2

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
  leadLength1 = (housing.leadSpan1.nom - housing.bodyWidth.nom) / 2
  leadLength2 = (housing.leadSpan2.nom - housing.bodyLength.nom) / 2
  # Body
  pattern.addRectangle { x: -bodyWidth/2, y: -bodyLength/2, width: bodyWidth, height: bodyLength }
  # Leads
  y = -pitch * (leadCount1/2 - 0.5)
  for i in [1..leadCount1]
    pattern.addLine { x1: -bodyWidth/2, y1: y, x2: -bodyWidth/2 - leadLength1, y2: y }
    pattern.addLine { x1: bodyWidth/2,  y1: y, x2: bodyWidth/2 + leadLength1,  y2: y }
    y += pitch

  x = -pitch * (leadCount2/2 - 0.5)
  for i in [1..leadCount2]
    pattern.addLine { x1: x, y1: -bodyLength/2, x2: x, y2: -bodyLength/2 - leadLength2 }
    pattern.addLine { x1: x, y1: bodyLength/2,  x2: x, y2: bodyLength/2 + leadLength2 }
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
    y: bodyLength/2 + leadLength2 + fontSize/2 + 0.5
    halign: 'center'
    valign: 'center'
