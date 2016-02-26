module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  pattern.name ?= 'CK_' + element.name

  pad =
    type: 'smd'
    shape: 'rectangle'
    width: 0.9
    height: 1
    layer: ['topCopper', 'topMask', 'topPaste']
    x: -2.05
    y: -0.8

  # Copper
  pattern.pad 1, pad
  pad.y = -pad.y
  pattern.pad 2, pad
  pad.x = -pad.x
  pad.y = -pad.y
  pattern.pad 3, pad
  pad.y = -pad.y
  pattern.pad 4, pad
  pad.width = 1.7
  pad.height = 0.55
  pad.x = 0
  pad.y = 1.425
  pattern.pad 5, pad

  firstPad = pattern.pads[1]
  lastPad = pattern.pads[5]

  # Silkscreen
  lineWidth = settings.lineWidth.silkscreen
  bodyWidth = 4.2
  bodyLength = 2.8
  x1 = firstPad.x + firstPad.width/2 + settings.clearance.padToSilk + lineWidth/2
  y = -bodyLength/2 - lineWidth/2
  x2 = -lastPad.width/2 - settings.clearance.padToSilk - lineWidth/2
  pattern
    .layer 'topSilkscreen'
    .lineWidth lineWidth
    .attribute 'refDes',
      x: 0
      y: 0
      halign: 'center'
      valign: 'center'
    .line -x1, y, x1, y
    .line x1, -y, x2, -y
    .line -x1, -y, -x2, -y

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
  courtyard = { L: 0.12, N: 0.25, M: 0.50 }[settings.densityLevel];

  x1 = firstPad.x - firstPad.width/2 - courtyard
  y1 = firstPad.y - firstPad.height/2 - courtyard
  x2 = -lastPad.width/2 - courtyard
  y2 = lastPad.y + lastPad.height/2 + courtyard

  pattern
    .layer 'topCourtyard'
    .lineWidth settings.lineWidth.courtyard
    # Centroid origin marking
    .circle 0, 0, 0.5
    .line -0.7, 0, 0.7, 0
    .line 0, -0.7, 0, 0.7
    # Contour courtyard
    .moveTo x1, y1
    .lineTo x1, -y1
    .lineTo x2, -y1
    .lineTo x2, y2
    .lineTo -x2, y2
    .lineTo -x2, -y1
    .lineTo -x1, -y1
    .lineTo -x1, y1
    .lineTo x1, y1
