module.exports =
  body: (pattern, housing, courtyard) ->
    settings = pattern.settings
    courtyard ?=  housing.courtyard ? { M: 0.5, N: 0.25, L: 0.12 }[settings.densityLevel]
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    x = bodyWidth/2 + courtyard
    y = bodyLength/2 + courtyard

    @preamble pattern, housing
      .rectangle  -x, -y, x, y

  connector: (pattern, housing, courtyard) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    x = bodyWidth/2 + courtyard
    y = bodyLength/2 + courtyard

    @preamble pattern, housing
      .rectangle  -x, -y, x, y

  boundary: (pattern, housing, courtyard) ->
    pads = pattern.pads
    xmin = -housing.bodyWidth.nom/2
    ymin = -housing.bodyLength.nom/2
    xmax = housing.bodyWidth.nom/2
    ymax = housing.bodyLength.nom/2
    for k, v of pads
      if xmin > v.x - v.width/2 then xmin = v.x - v.width/2
      if xmax < v.x + v.width/2 then xmax = v.x + v.width/2
      if ymin > v.y - v.height/2 then ymin = v.y - v.height/2
      if ymax < v.y + v.height/2 then ymax = v.y + v.height/2
    @preamble pattern, housing
      .rectangle xmin - courtyard, ymin - courtyard, xmax + courtyard, ymax + courtyard

  dual: (pattern, housing, courtyard) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    housing.bodyPosition ?= '0, 0'
    bodyPosition = pattern.parsePosition housing.bodyPosition
    [bodyX, bodyY] = [bodyPosition[0].x, bodyPosition[0].y]

    [firstPad, lastPad] = pattern.extremePads()

    x1 = firstPad.x - firstPad.width/2 - courtyard
    x2 = -bodyWidth/2 - courtyard
    if x1 > x2 then x1 = x2
    x3 = bodyWidth/2 + courtyard
    x4 = lastPad.x + lastPad.width/2 + courtyard
    if x4 < x3 then x4 = x3
    y1 = -bodyLength/2 - courtyard
    yl2 = firstPad.y - firstPad.height/2 - courtyard
    if y1 > yl2 then y1 = yl2
    yr2 = lastPad.y - lastPad.height/2 - courtyard
    if y1 > yr2 then y1 = yr2
    yl3 = -yl2 - 2*bodyY
    yr3 = -yr2 - 2*bodyY
    y4 = bodyLength/2 + courtyard

    @preamble pattern, housing
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

  gridArray: (pattern, housing, courtyard) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = pattern.extremePads()

    x1 = Math.min(-bodyWidth/2, firstPad.x - firstPad.width/2) - courtyard
    y1 = Math.min(-bodyLength/2, firstPad.y - firstPad.height/2) - courtyard
    x2 = Math.max(bodyWidth/2, lastPad.x - lastPad.width/2) + courtyard
    y2 = Math.max(bodyLength/2, lastPad.y - lastPad.height/2) + courtyard

    @preamble pattern, housing
      .rectangle x1, y1, x2, y2

  pak: (pattern, housing, courtyard) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom
    leadSpan = housing.leadSpan.nom
    tabLedge = housing.tabLedge.nom ? housing.tabLedge

    [firstPad, lastPad] = pattern.extremePads()

    x1 = firstPad.x - firstPad.width/2 - courtyard
    x2 = leadSpan/2 - tabLedge - bodyWidth - courtyard
    x3 = lastPad.x - lastPad.width/2 - courtyard
    x4 = leadSpan/2 - tabLedge + courtyard
    x5 = lastPad.x + lastPad.width/2 + courtyard
    y1 = firstPad.y - firstPad.height/2 - courtyard
    y2 = -bodyLength/2 - courtyard
    y3 = lastPad.y - lastPad.height/2 - courtyard
    ym = Math.min y2, y3

    @preamble pattern, housing
      .moveTo x1, y1
      .lineTo x2, y1
      .lineTo x2, y2
      .lineTo x3, y2
      .lineTo x3, ym
      .lineTo x4, ym
      .lineTo x4, y3
      .lineTo x5, y3
      .lineTo x5, -y3
      .lineTo x4, -y3
      .lineTo x4, -ym
      .lineTo x3, -ym
      .lineTo x3, -y2
      .lineTo x2, -y2
      .lineTo x2, -y1
      .lineTo x1, -y1
      .lineTo x1, y1

  preamble: (pattern, housing) ->
    @_centroid pattern

  quad: (pattern, housing, courtyard) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = pattern.extremePads()

    x1 = firstPad.x - firstPad.width/2 - courtyard
    x2 = -bodyWidth/2  - courtyard
    x3 = lastPad.x - lastPad.width/2 - courtyard
    if x1 > x2 then x1 = x2
    if x2 > x3 then x2 = x3
    x4 = -x3
    x5 = -x2
    x6 = -x1

    y1 = lastPad.y - lastPad.height/2 - courtyard
    y2 = -bodyLength/2 - courtyard
    y3 = firstPad.y - firstPad.height/2 - courtyard
    if y1 > y2 then y1 = y2
    if y2 > y3 then y2 = y3
    y4 = -y3
    y5 = -y2
    y6 = -y1

    @preamble pattern, housing
      .moveTo x1, y3
      .lineTo x2, y3
      .lineTo x2, y2
      .lineTo x3, y2
      .lineTo x3, y1
      .lineTo x4, y1
      .lineTo x4, y2
      .lineTo x5, y2
      .lineTo x5, y3
      .lineTo x6, y3
      .lineTo x6, y4
      .lineTo x5, y4
      .lineTo x5, y5
      .lineTo x4, y5
      .lineTo x4, y6
      .lineTo x3, y6
      .lineTo x3, y5
      .lineTo x2, y5
      .lineTo x2, y4
      .lineTo x1, y4
      .lineTo x1, y3

  twoPin: (pattern, housing, courtyard) ->
    if housing.bodyWidth? and housing.bodyLength?
      bodyWidth = housing.bodyWidth.nom
      bodyLength = housing.bodyLength.nom

      [firstPad, lastPad] = pattern.extremePads()

      x1 = firstPad.width/2 + courtyard
      x2 = bodyWidth/2 + courtyard
      xm = Math.max x1, x2
      y1 = lastPad.y + lastPad.height/2 + courtyard
      y2 = bodyLength/2 + courtyard
      @preamble pattern, housing
        .moveTo -x1, -y1
        .lineTo -x1, -y2
        .lineTo -xm, -y2
        .lineTo -xm,  y2
        .lineTo -x1,  y2
        .lineTo -x1,  y1
        .lineTo  x1,  y1
        .lineTo  x1,  y2
        .lineTo  xm,  y2
        .lineTo  xm, -y2
        .lineTo  x1, -y2
        .lineTo  x1, -y1
        .lineTo -x1, -y1
    else if housing.bodyDiameter?
      @preamble pattern, housing
        .circle 0, 0, housing.bodyDiameter.nom/2 + courtyard

  _centroid: (pattern) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.courtyard
    pattern
      .layer 'topCourtyard'
      .lineWidth lineWidth
      # Centroid origin marking
      .circle 0, 0, 0.5
      .line -0.7, 0, 0.7, 0
      .line 0, -0.7, 0, 0.7
