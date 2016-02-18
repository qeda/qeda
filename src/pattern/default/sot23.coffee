sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
sop = require './sop'
log = require '../../qeda-log'

module.exports = (pattern, element) ->
  housing = element.housing
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "SOT%dP%dX%d-%d",
    [housing.pitch*100
    housing.leadSpan.nom*100
    height*100
    housing.leadCount]
    .map((v) => Math.round v)...

  settings = pattern.settings

  if (housing.leadCount is 6) or (housing.leadCount is 8)
    sop pattern, element
  else
    # Calculate pad dimensions according to IPC-7351
    padParams = calculator.sop pattern, housing

    switch housing.leadCount
      when 3 then leftCount = 1
      when 5 then leftCount = 3
      else log.error "Wrong lead count (#{housing.leadCount})"

    pad =
      type: 'smd'
      shape: 'rectangle'
      width: padParams.width
      height: padParams.height
      layer: ['topCopper', 'topMask', 'topPaste']

    # Pads on the left side
    pad.x = -padParams.distance / 2
    y = -housing.pitch * (leftCount/2 - 0.5)
    for i in [1..leftCount]
      pad.y = y
      pattern.pad i, pad
      y += housing.pitch

    # Pads on the right side
    pad.x = padParams.distance / 2
    pad.y = housing.pitch
    pattern.pad leftCount + 1, pad
    pad.y -= 2*housing.pitch
    pattern.pad leftCount + 2, pad

    firstPad = pattern.pads[1]
    lastPad = pattern.pads[housing.leadCount]

    # Silkscreen
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom
    gap = lineWidth/2 + settings.clearance.padToSilk

    x = bodyWidth/2 + lineWidth/2
    y1 = -bodyLength/2 - lineWidth/2
    y2 = firstPad.y - firstPad.height/2 - gap
    if y1 > y2 then y1 = y2
    y3 = lastPad.y + lastPad.height/2 + gap

    pattern
      .layer 'topSilkscreen'
      .lineWidth lineWidth
      .attribute 'refDes',
        x: 0
        y: 0
        angle: 90
        halign: 'center'
        valign: 'center'
      .moveTo  x, y2
      .lineTo  x, y1
      .lineTo -x, y1
      .lineTo -x, y2
      .lineTo -x - firstPad.width, y2
      .moveTo  x, -y2
      .lineTo  x, -y1
      .lineTo -x, -y1
      .lineTo -x, -y2
      .line    x, -y3, x, y3
      .polarityMark firstPad.x - firstPad.width/2 - settings.clearance.padToSilk, firstPad.y

    # Assembly
    x = bodyWidth/2
    y = bodyLength/2
    d = 1
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
    x1 = -bodyWidth/2 - courtyard
    y1 = -bodyLength/2 - courtyard
    x2 = firstPad.x - firstPad.width/2 - courtyard
    y2 = firstPad.y - firstPad.height/2 - courtyard
    if y1 > y2 then y1 = y2
    pattern
      .layer 'topCourtyard'
      .lineWidth settings.lineWidth.courtyard
      # Centroid origin marking
      .circle 0, 0, 0.5
      .line -0.7, 0, 0.7, 0
      .line 0, -0.7, 0, 0.7
      # Contour courtyard
      .moveTo  x1,  y1
      .lineTo  x1,  y2
      .lineTo  x2,  y2
      .lineTo  x2, -y2
      .lineTo  x1, -y2
      .lineTo  x1, -y2
      .lineTo  x1, -y1
      .lineTo -x1, -y1
      .lineTo -x1, -y2
      .lineTo -x2, -y2
      .lineTo -x2,  y2
      .lineTo -x1,  y2
      .lineTo -x1,  y1
      .lineTo  x1,  y1
