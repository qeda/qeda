module.exports =
  dual: (pattern, housing, courtyard) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = @_pads pattern

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

    @_centroid pattern
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

    [firstPad, lastPad] = @_pads pattern

    x1 = Math.min(-bodyWidth/2, firstPad.x - firstPad.width/2) - courtyard
    y1 = Math.min(-bodyLength/2, firstPad.y - firstPad.height/2) - courtyard
    x2 = Math.max(bodyWidth/2, lastPad.x - lastPad.width/2) + courtyard
    y2 = Math.max(bodyLength/2, lastPad.y - lastPad.height/2) + courtyard

    @_centroid pattern
      .rectangle x1, y1, x2, y2

  qfn: (pattern, housing, courtyard) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = @_pads pattern

    x = Math.min(-bodyWidth/2, firstPad.x - firstPad.width/2) - courtyard
    y = Math.min(-bodyLength/2, lastPad.y - lastPad.height/2) - courtyard

    @_centroid pattern
      .rectangle -x, -y, x, y

  quad: (pattern, housing, courtyard) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = @_pads pattern

    x = -bodyWidth/2 - courtyard
    y = -bodyLength/2 - courtyard
    x1 = firstPad.x - firstPad.width/2 - courtyard
    y1 = firstPad.y - firstPad.height/2 - courtyard
    x2 = lastPad.x - lastPad.width/2 - courtyard
    y2 = lastPad.y - lastPad.height/2 - courtyard

    @_centroid pattern
      .moveTo  x1,  y1
      .lineTo  x,   y1
      .lineTo  x,   y
      .lineTo  x2,  y
      .lineTo  x2,  y2

      .lineTo -x2,  y2
      .lineTo -x2,  y
      .lineTo -x,   y
      .lineTo -x,   y1
      .lineTo -x1,  y1

      .lineTo -x1, -y1
      .lineTo -x,  -y1
      .lineTo -x,  -y
      .lineTo -x2, -y
      .lineTo -x2, -y2

      .lineTo x2, -y2
      .lineTo x2, -y
      .lineTo x,  -y
      .lineTo x,  -y1
      .lineTo x1, -y1

      .lineTo x1, y1

  twoPin: (pattern, housing, courtyard) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = @_pads pattern

    x1 = lastPad.x + lastPad.width/2 + courtyard
    x2 = bodyLength/2 + courtyard
    y1 = firstPad.height/2 + courtyard
    y2 = bodyWidth/2 + courtyard
    ym = Math.max y1, y2
    @_centroid pattern
      .moveTo -x1, -y1
      .lineTo -x2, -y1
      .lineTo -x2, -ym
      .lineTo x2, -ym
      .lineTo x2, -y1
      .lineTo x1, -y1
      .lineTo x1, y1
      .lineTo x2, y1
      .lineTo x2, ym
      .lineTo -x2, ym
      .lineTo -x2, y1
      .lineTo -x1, y1
      .lineTo -x1, -y1

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

  _pads: (pattern) ->
    numbers = Object.keys pattern.pads
    firstPad = pattern.pads[numbers[0]]
    lastPad = pattern.pads[numbers[numbers.length - 1]]
    [firstPad, lastPad]
