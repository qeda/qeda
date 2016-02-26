sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
sop = require './sop'
log = require '../../qeda-log'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "SOT%dP%dX%d-%d%s",
    [housing.pitch*100
    housing.leadSpan.nom*100
    height*100
    housing.leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  if (housing.leadCount % 2) is 0 # Even
    sop pattern, element
  else # Odd
    # Calculate pad dimensions according to IPC-7351
    padParams = calculator.sop pattern, housing

    switch housing.leadCount
      when 3
        leftCount = 2
        leftPitch = housing.pitch * 2
        rightCount = 1
        rightPitch = housing.pitch
      when 5
        leftCount = 3
        leftPitch = housing.pitch
        rightCount = 2
        rightPitch = housing.pitch * 2
      else log.error "Wrong lead count (#{housing.leadCount})"

    pad =
      type: 'smd'
      shape: 'rectangle'
      width: padParams.width
      height: padParams.height
      layer: ['topCopper', 'topMask', 'topPaste']

    # Pads on the left side
    pad.x = -padParams.distance / 2
    y = -leftPitch * (leftCount/2 - 0.5)
    for i in [1..leftCount]
      pad.y = y
      pattern.pad i, pad
      y += leftPitch

    # Pads on the right side
    pad.x = padParams.distance / 2
    y = rightPitch * (rightCount/2 - 0.5)
    for i in [1..rightCount]
      pad.y = y
      pattern.pad leftCount + i, pad
      y -= rightPitch

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
    #if y1 > y2 then y1 = y2
    y3 = lastPad.y - lastPad.height/2 - gap
    ym1 = Math.min y1, y2
    ym2 = Math.min y1, y3

    pattern
      .layer 'topSilkscreen'
      .lineWidth lineWidth
      .attribute 'refDes',
        x: 0
        y: 0
        halign: 'center'
        valign: 'center'
      .moveTo  x, ym2
      .lineTo  x, ym1
      .lineTo -x, ym1
      .lineTo -x, y2
      .lineTo firstPad.x - firstPad.width/2, y2
      .moveTo  x, -ym2
      .lineTo  x, -ym1
      .lineTo -x, -ym1
      .lineTo -x, -y2
      .lineTo -x, -ym1

      #.line    x, -y3, x, y3

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
    x1 = firstPad.x - firstPad.width/2 - courtyard
    x2 = -bodyWidth/2 - courtyard
    x3 = -x2
    x4 = lastPad.x + lastPad.width/2 + courtyard
    y1 = -bodyLength/2 - courtyard
    yl2 = firstPad.y - firstPad.height/2 - courtyard
    yr2 = lastPad.y - lastPad.height/2 - courtyard
    yl3 = -yl2
    yr3 = -yr2
    y4 = -y1
    pattern
      .layer 'topCourtyard'
      .lineWidth settings.lineWidth.courtyard
      # Centroid origin marking
      .circle 0, 0, 0.5
      .line -0.7, 0, 0.7, 0
      .line 0, -0.7, 0, 0.7
      # Contour courtyard
      .moveTo  x1,  yl2
      .lineTo x2, yl2
      .lineTo x2, y1
      .lineTo x3, y1
      .lineTo x3, yr2
      .lineTo x4, yr2
      .lineTo x4, yr3
      .lineTo x3, yr3
      .lineTo x3, y4
      .lineTo x2, y4
      .lineTo x2, yl3
      .lineTo x1, yl3
      .lineTo x1, yl2
      ###
      .moveTo  x1,  ym1
      .lineTo  x1,  y2
      .lineTo  x2,  y2
      .lineTo  x2, -y2
      .lineTo  x1, -y2
      .lineTo  x1, -y2
      .lineTo  x1, -ym2
      .lineTo -x1, -ym2
      .lineTo -x1, -y2
      .lineTo -x2, -y2
      .lineTo -x2,  y2
      .lineTo -x1,  y2
      .lineTo -x1,  y1
      .lineTo  x1,  y1
      ###
