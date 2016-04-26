module.exports =
  body: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = pattern.extremePads()

    x = bodyWidth/2 + lineWidth/2
    y = bodyLength/2 + lineWidth/2

    @preamble pattern, housing
      .rectangle  -x, -y, x, y

  connector: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = pattern.extremePads()

    x = bodyWidth/2 + lineWidth/2
    y = bodyLength/2 + lineWidth/2

    @preamble pattern, housing
      .rectangle  -x, -y, x, y
      .polarityMark -x - lineWidth, firstPad.y

  dual: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    cp = pattern.cornerPads()

    gap = lineWidth/2 + settings.clearance.padToSilk

    x1 = cp.topLeft.x - cp.topLeft.width/2 - gap
    x2 = -bodyWidth/2  - lineWidth/2
    if x1 > x2 then x1 = x2
    x3 = bodyWidth/2 + lineWidth/2

    yl1 = -bodyLength/2 - lineWidth/2
    yl2 = cp.topLeft.y - cp.topLeft.height/2 - gap
    if yl1 > yl2 then yl1 = yl2
    yl3 = cp.topLeft.y + cp.topLeft.height/2 # Polarity
    yl4 = cp.bottomLeft.y + cp.bottomLeft.height/2 + gap
    yl5 = bodyLength/2 + lineWidth/2
    if yl4 > yl5 then yl4 = yl5

    yr1 = -bodyLength/2 - lineWidth/2
    yr2 = cp.topRight.y - cp.topRight.height/2 - gap
    if yr1 > yr2 then yr1 = yr2
    yr3 = cp.bottomRight.y + cp.bottomRight.height/2 + gap
    yr4 = bodyLength/2 + lineWidth/2
    if yr3 > yr4 then yl3 = yr4

    xp = cp.topLeft.x
    yp = (if xp < x2 then yl2 else yl1) - lineWidth

    @preamble pattern, housing
    if housing.polarized
      pattern
        .polarityMark xp, yp, 'top'
        # Top contour
        .moveTo x1, yl3
        .lineTo x1, yl2
        .lineTo x2, yl2
    pattern
      .moveTo x2, yl2
      .lineTo x2, yl1
      .lineTo x3, yr1
      .lineTo x3, yr2
      # Bottom contour
      .moveTo x2, yl4
      .lineTo x2, yl5
      .lineTo x3, yr4
      .lineTo x3, yr3

  gridArray: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    x = bodyWidth/2 + lineWidth/2
    y = bodyLength/2 + lineWidth/2
    dx = x - housing.columnPitch * (housing.columnCount/2 - 0.5)
    dy = y - housing.rowPitch * (housing.rowCount/2 - 0.5)
    d = Math.min dx, dy
    len = Math.min 2*housing.columnPitch, 2*housing.rowPitch, x, y

    @preamble pattern, housing
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

  pak: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom
    leadSpan = housing.leadSpan.nom
    tabLedge = housing.tabLedge.nom ? housing.tabLedge

    [firstPad, lastPad] = pattern.extremePads()

    gap = lineWidth/2 + settings.clearance.padToSilk

    x1 = firstPad.x - firstPad.width/2 - gap
    x3 = lastPad.x - lastPad.width/2 - gap
    x4 = leadSpan/2 - tabLedge
    x2 = x4 - bodyWidth - lineWidth/2
    y0 = firstPad.y + firstPad.height/2
    y1 = firstPad.y - firstPad.height/2 - gap
    y2 = -bodyLength/2 - lineWidth/2
    y3 = lastPad.y - lastPad.height/2 - gap
    ym = Math.min y2, y3

    xp = firstPad.x
    yp = y1 - lineWidth

    @preamble pattern, housing
      .polarityMark xp, yp, 'top'
      .moveTo x1, y0
      .lineTo x1, y1
      .lineTo x2, y1
      .lineTo x2, y2
      .lineTo x3, y2
      .lineTo x3, ym
      .lineTo x4, ym
      .lineTo x4, y3
      .moveTo x2, -y1
      .lineTo x2, -y2
      .lineTo x3, -y2
      .lineTo x3, -ym
      .lineTo x4, -ym
      .lineTo x4, -y3

  preamble: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    pattern
      .layer 'topSilkscreen'
      .lineWidth lineWidth
      .attribute 'refDes',
        x: 0
        y: 0
        halign: 'center'
        valign: 'center'
    if housing.silkscreen? then pattern.path(housing.silkscreen) else pattern

  quad: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = pattern.extremePads()

    gap = lineWidth/2 + settings.clearance.padToSilk

    x1 = firstPad.x - firstPad.width/2 - gap
    x2 = -bodyWidth/2  - lineWidth/2
    x3 = lastPad.x - lastPad.width/2 - gap
    if x1 > x2 then x1 = x2
    if x2 > x3 then x2 = x3
    x4 = -x3
    x5 = -x2

    y1 = -bodyLength/2 - lineWidth/2
    y2 = firstPad.y - firstPad.height/2 - gap
    if y1 > y2 then y1 = y2
    y3 = firstPad.y + firstPad.height/2
    y4 = -y2
    y5 = -y1

    xp = firstPad.x
    yp = (if xp < x2 then y2 else y1) - lineWidth

    @preamble pattern, housing
      .polarityMark xp, yp, 'top'
      # Top left contour
      .moveTo x1, y3
      .lineTo x1, y2
      .lineTo x2, y2
      .lineTo x2, y1
      .lineTo x3, y1
      # Top right contour
      .moveTo x4, y1
      .lineTo x5, y1
      .lineTo x5, y2
      # Bottom left contour
      .moveTo x2, y4
      .lineTo x2, y5
      .lineTo x3, y5
      # Bottom right contour
      .moveTo x4, y5
      .lineTo x5, y5
      .lineTo x5, y4

  twoPin: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom
    leadWidth = housing.leadWidth.nom

    [firstPad, lastPad] = pattern.extremePads()

    gap = lineWidth/2 + settings.clearance.padToSilk

    x1 = firstPad.width/2 + gap
    x2 = bodyWidth/2 + lineWidth/2
    x = Math.max x1, x2
    y = bodyLength/2 + lineWidth/2
    @preamble pattern, housing
    if housing.cae
      d = x2 - x1
      pattern
        .moveTo -x1, -y
        .lineTo -x2, -y + d
        .lineTo -x2, y
        .lineTo -x1, y
        .moveTo x1, -y
        .lineTo x2, -y + d
        .lineTo x2, y
        .lineTo x1, y
    else
      pattern
        .line -x, -y, -x, y
        .line x, -y, x, y

      if x1 < x2 # Molded
        pattern
         .line -x1, -y, -x2, -y
         .line -x1,  y, -x2, y
         .line  x1, -y,  x2,  -y
         .line  x1,  y,  x2,  y

    if housing.polarized or housing.cae
      y2 = firstPad.y - firstPad.height/2 - gap
      pattern
       .moveTo -x1, -y
       .lineTo -x1, y2
       .lineTo x1, y2
       .lineTo x1, -y
       .polarityMark 0, y2 - lineWidth/2, 'top'
