module.exports =
  dual: (pattern, padParams) ->
    distance = padParams.distance
    pitch = padParams.pitch
    count = padParams.count
    pad = padParams.pad
    order = padParams.order ? 'round'
    mirror = padParams.mirror ? false
    numbers = switch order
      when 'round'
        [1..count/2].concat(i for i in [count..(count/2 + 1)] by -1)
      when 'rows'
        (i for i in [1..count] by 2).concat(j for j in [2..count] by 2)
      else # 'columns'
        [1..count]

    # Pads on the left side
    pad.x = if mirror then (distance / 2) else (-distance / 2)
    y = -pitch * (count/4 - 0.5)
    for i in [0..(count/2 - 1)]
      pad.y = y
      pattern.pad numbers[i], pad
      y += pitch

    # Pads on the right side
    pad.x = if mirror then (-distance / 2) else (distance / 2)
    y = -pitch * (count/4 - 0.5)
    for i in [(count/2)..(count - 1)]
      pad.y = y
      pattern.pad numbers[i], pad
      y += pitch

  gridArray: (pattern, element, pad) ->
    housing = element.housing
    rowPitch = housing.rowPitch
    columnPitch = housing.columnPitch
    rowCount = housing.rowCount
    columnCount = housing.columnCount

    gridLetters = element.gridLetters
    pins = element.pins

    # Grid array
    y = -rowPitch * (rowCount/2 - 0.5)
    for row in [1..rowCount]
      x = -columnPitch * (columnCount/2 - 0.5)
      for column in [1..columnCount]
        pad.x = x
        pad.y = y
        name = gridLetters[row] + column
        if pins[name]? then pattern.pad name, pad # Add only if exists
        x += columnPitch
      y += rowPitch

  quad: (pattern, padParams) ->
    pitch = padParams.pitch
    rowCount = padParams.rowCount
    columnCount = padParams.columnCount
    rowPad = padParams.rowPad
    columnPad = padParams.columnPad
    distance1 = padParams.distance1
    distance2 = padParams.distance2

    # Pads on the left side
    rowPad.x = -distance1 / 2
    y = -pitch * (rowCount/2 - 0.5)
    num = 1
    for i in [1..rowCount]
      rowPad.y = y
      pattern.pad num++, rowPad
      y += pitch

    # Pads on the bottom side
    x = -pitch * (columnCount/2 - 0.5)
    columnPad.y = distance2 / 2
    for i in [1..columnCount]
      columnPad.x = x
      pattern.pad num++, columnPad
      x += pitch

    # Pads on the right side
    rowPad.x = distance1 / 2
    y -= pitch
    for i in [1..rowCount]
      rowPad.y = y
      pattern.pad num++, rowPad
      y -= pitch

    # Pads on the top side
    x -= pitch
    columnPad.y = -distance2 / 2
    for i in [1..columnCount]
      columnPad.x = x
      pattern.pad num++, columnPad
      x -= pitch

  tab: (pattern, housing) ->
    hasTab = housing.tabWidth? and housing.tabLength?
    if hasTab
      housing.tabPosition ?= '0, 0'
      [x, y] = housing.tabPosition.replace(/\s+/g, '').split(',').map((v) => parseFloat(v))

      tabNumber = (housing.leadCount ? 2*(housing.rowCount + housing.columnCount)) + 1
      tabPad =
        type: 'smd'
        shape: 'rectangle'
        width: housing.tabWidth.nom ? housing.tabWidth
        height: housing.tabLength.nom ? housing.tabLength
        layer: ['topCopper', 'topMask', 'topPaste']
        x: x
        y: y
      pattern.pad tabNumber, tabPad
