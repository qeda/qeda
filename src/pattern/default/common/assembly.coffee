module.exports =
  body: (pattern, housing) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    x = bodyWidth/2
    y = bodyLength/2

    @_preamble pattern, housing
      .rectangle -x, -y, x, y

  polarized: (pattern, housing) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    x = bodyWidth/2
    y = bodyLength/2
    d = Math.min 1, bodyWidth/2, bodyLength/2

    @_preamble pattern, housing
      .moveTo -x + d, -y
      .lineTo  x, -y
      .lineTo  x,  y
      .lineTo -x,  y
      .lineTo -x, -y + d
      .lineTo -x + d, -y

  twoPin: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.assembly
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    x = bodyLength/2
    y = bodyWidth/2
    @_preamble pattern, housing, true
    ###  .layer 'topAssembly'
      .lineWidth settings.lineWidth.assembly
      .attribute 'value',
        text: pattern.name
        x: 0
        y: y + settings.fontSize.value/2 + 0.5
        halign: 'center'
        valign: 'center'
        visible: false
    ###
    if housing.cae
      d = Math.min bodyWidth/4, bodyLength/4
      diam = housing.bodyDiameter.nom ? housing.bodyDiameter
      pattern
        .moveTo -x, -y + d
        .lineTo -x + d, -y
        .lineTo x, -y
        .lineTo x, y
        .lineTo -x + d, y
        .lineTo -x, y - d
        .lineTo -x, -y + d
      if diam? then  pattern.circle 0, 0, diam/2
    else if housing.polarized
      d = Math.min 1, bodyWidth/2, bodyLength/2
      pattern
        .moveTo -x, -y
        .lineTo x, -y
        .lineTo x, y
        .lineTo -x + d, y
        .lineTo -x, y - d
        .lineTo -x, -y
    else
      pattern.rectangle -x, -y, x, y

  _preamble: (pattern, housing, swap = false) ->
    @_refDes pattern, housing, swap
    @_value pattern, housing, swap

  _refDes: (pattern, housing, swap = false) ->
    settings = pattern.settings
    [w, h] = if swap then [housing.bodyLength.nom, housing.bodyWidth.nom] else [housing.bodyWidth.nom, housing.bodyLength.nom]
    lineWidth = settings.lineWidth.assembly
    angle = if w < h then 90 else 0
    fontSize = settings.fontSize.default
    maxFontSize = 0.66*Math.min(w, h)
    if fontSize > maxFontSize then fontSize = maxFontSize
    textLineWidth = Math.min(lineWidth, fontSize/5)
    pattern
      .layer 'topAssembly'
      .lineWidth textLineWidth
      .attribute 'user',
        text: 'REF**'
        x: 0
        y: 0
        angle: angle
        fontSize: fontSize
        halign: 'center'
        valign: 'center'
      .lineWidth lineWidth

  _value: (pattern, housing, swap = false) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.assembly
    y = if swap then housing.bodyWidth.nom/2 else housing.bodyLength.nom/2
    pattern
      .layer 'topAssembly'
      .lineWidth lineWidth
      .attribute 'value',
        text: pattern.name
        x: 0
        y: y + settings.fontSize.value/2 + 0.5
        halign: 'center'
        valign: 'center'
        visible: false
