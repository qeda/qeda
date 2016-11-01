module.exports =
  body: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    x = bodyWidth/2 + lineWidth/2
    y = bodyLength/2 + lineWidth/2

    @preamble pattern, housing
      .silkRectangle -x, -y, x, y

    if housing.polarized
      [firstPad, lastPad] = pattern.extremePads()
      gap = lineWidth/2 + settings.clearance.padToSilk
      xl = -bodyWidth/2
      xr = -xl
      yt = -bodyLength/2
      yb = -yt
      x = firstPad.x
      y = firstPad.y
      w = firstPad.width
      h = firstPad.height
      dxl = Math.abs(x - xl)
      dxr = Math.abs(x - xr)
      dyt = Math.abs(y - yt)
      dyb = Math.abs(y - yb)
      pos = 'top'
      delta = dyt
      xp = x
      yp = Math.min(yt - 1.5*lineWidth, y - h/2 - gap)
      if dxl < delta
        delta = dxl
        pos = 'left'
        xp = Math.min(xl - 1.5*lineWidth, x - w/2 - gap)
        yp = y
      if dxr < delta
        delta = dxr
        pos = 'right'
        xp = Math.max(xr + 1.5*lineWidth, x + w/2 + gap)
        yp = y
      if dyb < delta
        pos = 'bottom'
        xp = x
        yp = Math.max(yb + 1.5*lineWidth, y + h/2 + gap)
      pattern.polarityMark xp, yp, pos

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
      if xf < x1
        pattern
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
    dx = x - housing.horizontalPitch * (housing.columnCount/2 - 0.5)
    dy = y - housing.verticalPitch * (housing.rowCount/2 - 0.5)
    d = Math.min dx, dy
    len = Math.min 2*housing.horizontalPitch, 2*housing.verticalPitch, x, y

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

    [firstPad, lastPad] = pattern.extremePads()

    gap = lineWidth/2 + settings.clearance.padToSilk
    x1 = firstPad.width/2 + gap

    if housing.bodyWidth? and housing.bodyLength? # Rectangular
      bodyWidth = housing.bodyWidth.nom
      bodyLength = housing.bodyLength.nom

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

    else if housing.bodyDiameter? # Cylindrical
      r = housing.bodyDiameter.nom/2 + lineWidth/2
      @preamble pattern, housing
        .circle 0, 0, r
      if housing.polarized
        y = firstPad.y + firstPad.height/2 + gap
        pattern
          .rectangle -x1, -r, x1, y
          .polarityMark 0, -r - 1.5*lineWidth, 'top'
