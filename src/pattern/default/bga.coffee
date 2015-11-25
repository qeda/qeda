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
  padParams.pad =
    type: 'smd'
    width: padParams.width
    height: padParams.height
    shape: 'circle'
    mask: 0.001 # KiCad does not support zero value
    paste: -0.001 # KiCad does not support zero value
    layer: ['topCopper', 'topMask', 'topPaste']

  gridarray pattern, element, padParams

  # Silkscreen
  lineWidth = settings.lineWidth.silkscreen
  # Box
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom
  x = bodyWidth/2
  y = bodyLength/2
  dx = x - padParams.columnPitch * (padParams.columnCount/2 - 0.5)
  dy = y - padParams.rowPitch * (padParams.rowCount/2 - 0.5)
  d = Math.min dx, dy
  pattern
    .layer 'topSilkscreen'
    .lineWidth lineWidth
    .line -x, -y + d, -x + d, -y
    .line -x + d, -y, x, -y
    .line x, -y, x, y
    .line x, y, -x,  y
    .line -x, y, -x, -y + d
  # Key
  r = 0.25
  pattern
    .lineWidth r
    .circle -x, -y, r/2
  # RefDes
  fontSize = settings.fontSize.refDes
  pattern.attribute 'refDes',
    x: 0
    y: -bodyLength/2 - fontSize/2 - 2*lineWidth
    halign: 'center'
    valign: 'center'

  # Assembly
  pattern
    .layer 'topAssembly'
    .lineWidth settings.lineWidth.assembly
    .line -x, -y + d, -x + d, -y
    .line -x + d, -y, x, -y
    .line x,-y, x, y
    .line x, y, -x, y
    .line -x, y, -x, -y + d
  # Value
  fontSize = settings.fontSize.value
  pattern.attribute 'value',
    text: pattern.name
    x: 0
    y: bodyLength/2 + fontSize/2 + 0.5
    halign: 'center'
    valign: 'center'
