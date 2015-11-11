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
  rowCount = housing.rowCount
  columnCount = housing.columnCount

  pattern.setLayer 'topSilkscreen'
  lineWidth = settings.lineWidth.silkscreen
  pattern.setLineWidth lineWidth
  # Boundary
  x1 = -housing.bodyWidth.nom/2
  x2 = -pitch*(columnCount/2 - 0.5) - padHeight2/2 - lineWidth/2 - settings.clearance.padToSilk
  if x1 > x2 then x1 = x2
  y1 = -housing.bodyLength.nom/2
  y2 = -pitch*(rowCount/2 - 0.5) - padHeight1/2 - lineWidth/2 - settings.clearance.padToSilk
  if y1 > y2 then y1 = y2
  pattern.addLine { x1: x1, y1: y1, x2: x2, y2: y1 }
  pattern.addLine { x1: x1, y1: y1, x2: x1, y2: y2 }
  pattern.addLine { x1: -x1, y1: y1, x2: -x2, y2: y1 }
  pattern.addLine { x1: -x1, y1: y1, x2: -x1, y2: y2 }
  pattern.addLine { x1: x1, y1: -y1, x2: x2, y2: -y1 }
  pattern.addLine { x1: x1, y1: -y1, x2: x1, y2: -y2 }
  pattern.addLine { x1: -x1, y1: -y1, x2: -x2, y2: -y1 }
  pattern.addLine { x1: -x1, y1: -y1, x2: -x1, y2: -y2 }
  # First pin key
  r = 0.25
  x1 = (-padDistance1 - padWidth1)/2 - r - settings.clearance.padToSilk
  x2 = -housing.bodyWidth.nom/2 - r - settings.clearance.padToSilk
  x = Math.min x1, x2
  y = -pitch*(rowCount/2 - 0.5)
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
  # Body
  pattern.addRectangle { x: -bodyWidth/2, y: -bodyLength/2, width: bodyWidth, height: bodyLength }
  # Key
  r = 0.25
  shift = bodyWidth/2 - r
  if shift > 0.3 then shift = 0.3
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
