module.exports =
  body: (pattern, housing) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    x = bodyWidth/2
    y = bodyLength/2

    @_value pattern, housing
      .rectangle -x, -y, x, y

  polarized: (pattern, housing) ->
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    x = bodyWidth/2
    y = bodyLength/2
    d = Math.min 1, bodyWidth/2, bodyLength/2

    @_value pattern, housing
      .moveTo -x + d, -y
      .lineTo  x, -y
      .lineTo  x,  y
      .lineTo -x,  y
      .lineTo -x, -y + d
      .lineTo -x + d, -y

  twopin: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.assembly
    bodyWidth = housing.bodyWidth.nom
    bodyLength = housing.bodyLength.nom

    x = bodyLength/2
    y = bodyWidth/2
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

  _value: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.assembly
    pattern
      .layer 'topAssembly'
      .lineWidth lineWidth
      .attribute 'value',
        text: pattern.name
        x: 0
        y: housing.bodyLength.nom/2 + settings.fontSize.value/2 + 0.5
        halign: 'center'
        valign: 'center'
        visible: false
