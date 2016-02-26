sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
gridarray = require './common/gridarray'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  leadCount = housing.leadCount ? 2*(housing.rowCount + housing.columnCount)
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "BGA%d%s%dP%dX%d_%dX%dX%d%s",
    leadCount,
    if settings.ball.collapsible then 'C' else 'N'
    [housing.pitch*100
    housing.columnCount
    housing.rowCount
    housing.bodyLength.nom*100
    housing.bodyWidth.nom*100
    height*100]
    .map((v) => Math.round v)...,
    settings.densityLevel

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
    layer: ['topCopper', 'topMask', 'topPaste']

  gridarray pattern, element, padParams

  # Silkscreen
  lineWidth = settings.lineWidth.silkscreen
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom

  x = bodyWidth/2 + lineWidth/2
  y = bodyLength/2 + lineWidth/2
  dx = x - padParams.columnPitch * (padParams.columnCount/2 - 0.5)
  dy = y - padParams.rowPitch * (padParams.rowCount/2 - 0.5)
  d = Math.min dx, dy
  len = Math.min 2*padParams.columnPitch, 2*padParams.rowPitch, x, y
  pattern
    .layer 'topSilkscreen'
    .lineWidth lineWidth
    .attribute 'refDes',
      x: 0
      y: 0
      halign: 'center'
      valign: 'center'
    .moveTo -x, -y + len
    .lineTo -x, -y + d
    .lineTo -x + d, -y
    .lineTo -x + len, -y

    .moveTo x, -y + len
    .lineTo x, -y
    .lineTo x - len, -y

    .moveTo x, y - len
    .lineTo x, y
    .lineTo x - len, y

    .moveTo -x, y - len
    .lineTo -x, y
    .lineTo -x + len, y

    .polarityMark -x, -y, 'center'

  # Assembly
  x = bodyWidth/2
  y = bodyLength/2
  d = Math.min 1, bodyWidth/2, bodyLength/2
  pattern
    .layer 'topAssembly'
    .lineWidth settings.lineWidth.assembly
    .attribute 'value',
      text: pattern.name
      x: 0
      y: y + settings.fontSize.value/2 + 0.5
      halign: 'center'
      valign: 'center'
      visible: false
    .moveTo -x + d, -y
    .lineTo  x, -y
    .lineTo  x,  y
    .lineTo -x,  y
    .lineTo -x, -y + d
    .lineTo -x + d, -y

  # Courtyard
  courtyard = padParams.courtyard
  x = bodyWidth/2 + courtyard
  y = bodyLength/2 + courtyard

  pattern
    .layer 'topCourtyard'
    .lineWidth settings.lineWidth.courtyard
    # Centroid origin marking
    .circle 0, 0, 0.5
    .line -0.7, 0, 0.7, 0
    .line 0, -0.7, 0, 0.7
    # Contour courtyard
    .rectangle -x, -y, x, y
