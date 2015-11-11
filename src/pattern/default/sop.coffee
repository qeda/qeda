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

  pattern.setLayer 'top'
  dual pattern, padParams

  # Silkscreen
  padWidth = padParams.width
  padHeight = padParams.height
  padDistance = padParams.distance
  pitch = housing.pitch
  leadCount = housing.leadCount

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
