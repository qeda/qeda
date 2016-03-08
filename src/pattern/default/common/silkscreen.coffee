module.exports =
  connector: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = @_pads pattern

    x = bodyWidth/2 + lineWidth/2
    y = bodyLength/2 + lineWidth/2

    @_refDes pattern
      .rectangle  -x, -y, x, y
      .polarityMark -x - lineWidth, firstPad.y

  dual: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = @_pads pattern

    gap = lineWidth/2 + settings.clearance.padToSilk

    x1 = firstPad.x - firstPad.width/2 - gap
    x2 = -bodyWidth/2  - lineWidth/2
    if x1 > x2 then x1 = x2
    x3 = bodyWidth/2 + lineWidth/2

    y1 = -bodyLength/2 - lineWidth/2
    y2 = firstPad.y - firstPad.height/2 - gap
    if y1 > y2 then y1 = y2
    yl3 = firstPad.y + firstPad.height/2
    yr3 = lastPad.y - lastPad.height/2 - gap

    xp = firstPad.x
    yp = (if xp < x2 then y2 else y1) - lineWidth

    @_refDes pattern
      .polarityMark xp, yp, 'top'
      # Top contour
      .moveTo x1, yl3
      .lineTo x1, y2
      .lineTo x2, y2
      .lineTo x2, y1
      .lineTo x3, y1
      .lineTo x3, yr3
      # Bottom contour
      .moveTo x2, -y2
      .lineTo x2, -y1
      .lineTo x3, -y1
      .lineTo x3, -yr3

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

    @_refDes pattern
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

    [firstPad, lastPad] = @_pads pattern

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

    @_refDes pattern
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

  quad: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = @_pads pattern

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

    @_refDes pattern
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

    [firstPad, lastPad] = @_pads pattern

    gap = lineWidth/2 + settings.clearance.padToSilk

    x = bodyLength/2 + lineWidth/2
    y1 = firstPad.height/2 + gap
    y2 = bodyWidth/2 + lineWidth/2
    y = Math.max y1, y2
    @_refDes pattern
    if housing.cae
      d = y2 - y1
      pattern
        .moveTo -x, -y1
        .lineTo -x + d, -y2
        .lineTo x, -y2
        .lineTo x, -y1
        .moveTo -x, y1
        .lineTo -x + d, y2
        .lineTo x, y2
        .lineTo x, y1
    else
      pattern
        .line -x, -y, x, -y
        .line -x, y, x, y

      if y1 < y2 # Molded
        pattern
         .line -x, -y1, -x, -y2
         .line  x, -y1,  x, -y2
         .line -x,  y1, -x,  y2
         .line  x,  y1,  x,  y2

    if housing.polarized or housing.cae
      x2 = firstPad.x - firstPad.width/2 - gap
      pattern
       .moveTo -x, -y1
       .lineTo x2, -y1
       .lineTo x2, y1
       .lineTo -x, y1
       .polarityMark x2 - lineWidth/2, 0

  _pads: (pattern) ->
    numbers = Object.keys pattern.pads
    firstPad = pattern.pads[numbers[0]]
    lastPad = pattern.pads[numbers[numbers.length - 1]]
    [firstPad, lastPad]

  _refDes: (pattern) ->
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
