sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
quad = require './common/quad'

module.exports = (pattern, housing) ->
  pattern.name ?= sprintf "%sQFN%dP%dX%dX%d-%d",
    if housing.pullBack? then 'P' else '',
    [housing.pitch*100
    housing.bodyWidth.nom*100
    housing.bodyLength.nom*100
    housing.height*100
    housing.leadCount]
    .map((a) => Math.round a)...

  settings = pattern.settings

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.qfn pattern, housing
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
  # Boundary
  x1 = -housing.bodyWidth.nom/2
  x2 = -pitch*(leadCount2/2 - 0.5) - padHeight2/2 - lineWidth/2 - settings.clearance.padToSilk
  if x1 > x2 then x1 = x2
  y1 = -housing.bodyLength.nom/2
  y2 = -pitch*(leadCount1/2 - 0.5) - padHeight1/2 - lineWidth/2 - settings.clearance.padToSilk
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
  y = -pitch*(leadCount1/2 - 0.5)
  pattern.addCircle { x: x, y: y, radius: r/2, lineWidth: r }

  # Assembly
  pattern.setLayer 'topAssembly'
  pattern.setLineWidth settings.lineWidth.assembly
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom
  # Body
  pattern.addRectangle { x: -bodyWidth/2, y: -bodyLength/2, width: bodyWidth, height: bodyLength }
