module.exports =
  body: (pattern, housing) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    x = bodyWidth/2
    y = bodyLength/2

    @preamble pattern, housing
      .rectangle -x, -y, x, y

  pak: (pattern, element) ->
    housing = element.housing
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom
    leadSpan = housing.leadSpan.nom
    leadCount = housing.leadCount
    tabLedge = housing.tabLedge.nom ? housing.tabLedge
    tabWidth = housing.tabWidth.nom ? housing.tabWidth

    # Assembly
    x1 = leadSpan/2 - tabLedge
    x2 = x1 - bodyWidth
    @preamble pattern, housing
      .rectangle x1, -bodyLength/2, x2, bodyLength/2
      .rectangle x1, -tabWidth/2, x1 + tabLedge, tabWidth/2

    pins = element.pins
    y = -housing.pitch * (leadCount/2 - 0.5)
    for i in [1..leadCount]
      if pins[i]? then pattern.line -leadSpan/2, y, x2, y
      y += housing.pitch

  polarized: (pattern, housing) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    x = bodyWidth/2
    y = bodyLength/2
    d = Math.min 1, bodyWidth/2, bodyLength/2

    @preamble pattern, housing
      .moveTo -x + d, -y
      .lineTo  x, -y
      .lineTo  x,  y
      .lineTo -x,  y
      .lineTo -x, -y + d
      .lineTo -x + d, -y

  preamble: (pattern, housing) ->
    settings = pattern.settings
    w = if housing.bodyWidth? then housing.bodyWidth.nom else housing.bodyDiameter.nom
    h = if housing.bodyLength? then housing.bodyLength.nom else housing.bodyDiameter.nom
    lineWidth = settings.lineWidth.assembly
    angle = if w < h then 90 else 0
    fontSize = settings.fontSize.default
    maxFontSize = 0.66*Math.min(w, h)
    if fontSize > maxFontSize then fontSize = maxFontSize
    textLineWidth = Math.min(lineWidth, fontSize/5)
    pattern
      .layer 'topAssembly'
      .lineWidth textLineWidth
      .attribute 'value',
        text: pattern.name
        x: 0
        y: 0
        angle: angle
        fontSize: fontSize
        halign: 'center'
        valign: 'center'
      .attribute 'user',
        text: 'REF**'
        x: 0
        y: 0
        angle: angle
        fontSize: fontSize
        halign: 'center'
        valign: 'center'
        visible: false
      .lineWidth lineWidth

  twoPin: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.assembly

    @preamble pattern, housing

    if housing.bodyWidth? and housing.bodyLength?
      bodyWidth = housing.bodyWidth.nom
      bodyLength = housing.bodyLength.nom
      x = bodyWidth/2
      y = bodyLength/2
      if housing.cae
        d = Math.min bodyWidth/4, bodyLength/4
        diam = housing.bodyDiameter.nom ? housing.bodyDiameter
        pattern
          .moveTo -x + d, -y
          .lineTo -x, -y + d
          .lineTo -x, y
          .lineTo x, y
          .lineTo x, -y + d
          .lineTo x - d, -y
          .lineTo -x + d, -y
        if diam? then  pattern.circle 0, 0, diam/2
      else if housing.polarized
        d = Math.min 1, bodyWidth/2, bodyLength/2
        pattern
          .moveTo -x + d, -y
          .lineTo  x, -y
          .lineTo  x,  y
          .lineTo -x,  y
          .lineTo -x, -y + d
          .lineTo -x + d, -y
      else
        pattern.rectangle -x, -y, x, y
    else if housing.bodyDiameter?
      pattern.circle 0, 0, housing.bodyDiameter.nom/2
