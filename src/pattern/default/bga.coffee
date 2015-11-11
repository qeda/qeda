sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
gridarray = require './common/gridarray'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  leadCount = housing.leadCount ? 2*(housing.rowCount + housing.columnCount)
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "BGA%d%s%dP%dX%d_%dX%dX%d",
    leadCount,
    if settings.ball.collapsible then 'C' else 'N'
    [housing.pitch*100
    housing.columnCount
    housing.rowCount
    housing.bodyLength.nom*100
    housing.bodyWidth.nom*100
    height*100]
    .map((a) => Math.round a)...

  padParams = calculator.bga pattern, housing
  padParams.rowPitch = housing.rowPitch ? housing.pitch
  padParams.columnPitch = housing.columnPitch ? housing.pitch
  padParams.rowCount = housing.rowCount
  padParams.columnCount = housing.columnCount

  pattern.setLayer 'top'
  gridarray pattern, element, padParams

  # Silkscreen
  pattern.setLayer 'topSilkscreen'
  lineWidth = settings.lineWidth.silkscreen
  pattern.setLineWidth lineWidth
  # Box
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom
  x = bodyWidth/2
  y = bodyLength/2
  dx = x - padParams.columnPitch * (padParams.columnCount/2 - 0.5)
  dy = y - padParams.rowPitch * (padParams.rowCount/2 - 0.5)
  d = Math.min dx, dy
  pattern.addLine { x1: -x, y1: -y + d, x2: -x + d, y2: -y }
  pattern.addLine { x1: -x + d, y1: -y, x2: x, y2: -y }
  pattern.addLine { x1: x, y1: -y, x2: x, y2: y }
  pattern.addLine { x1: x, y1: y, x2: -x, y2: y }
  pattern.addLine { x1: -x, y1: y, x2: -x, y2: -y + d }
  # Key
  r = 0.25
  pattern.addCircle { x: -x, y: -y, radius: r/2, lineWidth: r}
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
  # Body
  pattern.addLine { x1: -x, y1: -y + d, x2: -x + d, y2: -y }
  pattern.addLine { x1: -x + d, y1: -y, x2: x, y2: -y }
  pattern.addLine { x1: x, y1: -y, x2: x, y2: y }
  pattern.addLine { x1: x, y1: y, x2: -x, y2: y }
  pattern.addLine { x1: -x, y1: y, x2: -x, y2: -y + d }
  # Value
  fontSize = settings.fontSize.value
  pattern.addAttribute 'value',
    text: pattern.name
    x: 0
    y: bodyLength/2 + fontSize/2 + 0.5
    halign: 'center'
    valign: 'center'
