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
      .silkRectangle -x, -y, x, y

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

    [firstPad, lastPad] = pattern.extremePads()

    gap = lineWidth/2 + settings.clearance.padToSilk

    x1 = -bodyWidth/2  - lineWidth/2
    x2 = -x1
    yb = -bodyLength/2 - lineWidth/2
    xf = firstPad.x - firstPad.width/2 - gap
    yf = firstPad.y - firstPad.height/2 - gap
    y1 = Math.min yb, yf
    y2 = -y1

    xp = firstPad.x
    yp = (if xp < x1 then yf else y1) - 1.5*lineWidth

    @preamble pattern, housing
      .silkRectangle x1, y1, x2, y2

    if housing.polarized
      pattern
        .polarityMark xp, yp, 'top'
        # Top contour
        .moveTo x1, yf
        .lineTo xf, yf
        .lineTo xf, yf + firstPad.height + gap

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

    dx = leadSpan/2 - tabLedge - bodyWidth/2

    x1 = dx - bodyWidth/2 - lineWidth/2
    x2 = dx + bodyWidth/2 + lineWidth/2
    y1 = -bodyLength/2 - lineWidth/2
    y2 = -y1
    xf = firstPad.x - firstPad.width/2 - gap
    yf = firstPad.y - firstPad.height/2 - gap
    xt = lastPad.x - lastPad.width/2 - gap
    yt = lastPad.y - lastPad.height/2 - gap

    xp = firstPad.x
    yp = (if xp < x1 then yf else y1) - 1.5*lineWidth

    @preamble pattern, housing
      .silkRectangle x1, y1, x2, y2
      .polarityMark xp, yp, 'top'
      .moveTo x1, yf
      .lineTo xf, yf
      .lineTo xf, yf + firstPad.height + gap

    if yt < y1 # Tab pad is greater than body
      pattern
        .moveTo x2, yt
        .lineTo xt, yt
        .lineTo xt, y1
        .moveTo x2, -yt
        .lineTo xt, -yt
        .lineTo xt, -y1

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

    x1 = -bodyWidth/2  - lineWidth/2
    x2 = -x1
    y1 = -bodyLength/2 - lineWidth/2
    y2 = -y1
    xf = firstPad.x - firstPad.width/2 - gap
    yf = firstPad.y - firstPad.height/2 - gap

    xp = firstPad.x
    yp = (if xp < x1 then yf else y1) - 1.5*lineWidth

    @preamble pattern, housing
      .silkRectangle x1, y1, x2, y2
      .polarityMark xp, yp, 'top'
      .moveTo x1, yf
      .lineTo xf, yf
      .lineTo xf, yf + firstPad.height + gap

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
       .polarityMark 0, y2 - 1.5*lineWidth, 'top'
