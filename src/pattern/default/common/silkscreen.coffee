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

    x = bodyWidth/2 + lineWidth/2
    y1 = -bodyLength/2 - lineWidth/2
    y2 = firstPad.y - firstPad.height/2 - gap
    if y1 > y2 then y1 = y2
    y3 = lastPad.y - lastPad.height/2 - gap

    @_refDes pattern
      .moveTo  x, y3
      .lineTo  x, y1
      .lineTo -x, y1
      .lineTo -x, y2
      .lineTo firstPad.x - firstPad.width/2, y2
      .moveTo  x, -y3
      .lineTo  x, -y1
      .lineTo -x, -y1
      .lineTo -x, -y2
      .polarityMark firstPad.x - firstPad.width/2 - settings.clearance.padToSilk, firstPad.y

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

  qfn: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = @_pads pattern

    gap = lineWidth/2 + settings.clearance.padToSilk

    x = -bodyWidth/2 - lineWidth/2
    y = -bodyLength/2 - lineWidth/2

    x1 = lastPad.x - lastPad.width/2 - gap
    if x > x1 then x = x1
    y1 = firstPad.y - firstPad.height/2 - gap
    if y > y1 then y = y1

    @_refDes pattern
      .moveTo  x1,  y
      .lineTo  x,   y

      .moveTo -x1,  y
      .lineTo -x,   y
      .lineTo -x,   y1

      .moveTo  x1, -y
      .lineTo  x,  -y
      .lineTo  x,  -y1

      .moveTo -x1, -y
      .lineTo -x,  -y
      .lineTo -x,  -y1

      .polarityMark firstPad.x - firstPad.width/2 - settings.clearance.padToSilk, firstPad.y

  qfp: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = @_pads pattern

    gap = lineWidth/2 + settings.clearance.padToSilk

    x = -bodyWidth/2 - lineWidth/2
    y = -bodyLength/2 - lineWidth/2

    x1 = lastPad.x - lastPad.width/2 - gap
    if x > x1 then x = x1
    y1 = firstPad.y - firstPad.height/2 - gap
    if y > y1 then y = y1

    @_refDes pattern
      .moveTo  x1,  y
      .lineTo  x,   y
      .lineTo  x,   y1
      .lineTo  x - firstPad.width, y1

      .moveTo -x1,  y
      .lineTo -x,   y
      .lineTo -x,   y1

      .moveTo  x1, -y
      .lineTo  x,  -y
      .lineTo  x,  -y1

      .moveTo -x1, -y
      .lineTo -x,  -y
      .lineTo -x,  -y1

      .polarityMark firstPad.x - firstPad.width/2 - settings.clearance.padToSilk, firstPad.y

  son: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.silkscreen
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    [firstPad, lastPad] = @_pads pattern

    gap = lineWidth/2 + settings.clearance.padToSilk

    x = bodyWidth/2 + lineWidth/2
    y1 = -bodyLength/2 - lineWidth/2
    y2 = firstPad.y - firstPad.height/2 - gap
    if y1 > y2 then y1 = y2
    y3 = lastPad.y - lastPad.height/2 - gap

    @_refDes pattern
      .moveTo  x, y3
      .lineTo  x, y1
      .lineTo -x, y1
      .moveTo  x, -y3
      .lineTo  x, -y1
      .lineTo -x, -y1
      .lineTo -x, -y2
      .polarityMark firstPad.x - firstPad.width/2 - settings.clearance.padToSilk, firstPad.y

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
