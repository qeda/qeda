module.exports =
  dual: (pattern, element, padParams) ->
    housing = element.housing
    pitch = housing.pitch
    count = housing.leadCount
    distance = padParams.distance
    pad = padParams.pad
    order = padParams.order ? 'round'
    mirror = padParams.mirror ? false
    pins = element.pins
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
      if pins[numbers[i]]? then pattern.pad numbers[i], pad
      y += pitch

    # Pads on the right side
    pad.x = if mirror then (-distance / 2) else (distance / 2)
    y = -pitch * (count/4 - 0.5)
    for i in [(count/2)..(count - 1)]
      pad.y = y
      if pins[numbers[i]]? then pattern.pad numbers[i], pad
      y += pitch

    @mask pattern

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
        if pins[name]? then pattern.pad name, pad
        x += columnPitch
      y += rowPitch

    @mask pattern

  mask: (pattern) ->
    settings = pattern.settings
    maskWidth = settings.minimum.maskWidth
    if maskWidth?
      pads = pattern.pads
      keys = Object.keys pads
      last = keys.length - 1
      for i in [0..last]
        for j in [(i+1)..last] by 1
          p1 = pads[keys[i]]
          p2 = pads[keys[j]]
          hspace = Math.abs(p2.x - p1.x) - (p1.width + p2.width)/2
          vspace = Math.abs(p2.y - p1.y) - (p1.height + p2.height)/2
          space = Math.max hspace, vspace
          mask = settings.clearance.padToMask
          if (space - 2*mask) < settings.minimum.maskWidth
            mask = (space - settings.minimum.maskWidth) / 2
            if mask < 0 then mask = 0
          if (not p1.mask?) or (mask < p1.mask) then p1.mask = mask
          if (not p2.mask?) or (mask < p2.mask) then p2.mask = mask

          #console.log j + ', ' + i + ' -> ' + space + ': ' + mask

  quad: (pattern, element, padParams) ->
    housing = element.housing
    pitch = housing.pitch
    rowCount = housing.rowCount
    columnCount = housing.columnCount
    rowPad = padParams.rowPad
    columnPad = padParams.columnPad
    distance1 = padParams.distance1
    distance2 = padParams.distance2
    pins = element.pins

    # Pads on the left side
    rowPad.x = -distance1 / 2
    y = -pitch * (rowCount/2 - 0.5)
    num = 1
    for i in [1..rowCount]
      rowPad.y = y
      if pins[num]? then pattern.pad num, rowPad
      ++num
      y += pitch

    # Pads on the bottom side
    x = -pitch * (columnCount/2 - 0.5)
    columnPad.y = distance2 / 2
    for i in [1..columnCount]
      columnPad.x = x
      if pins[num]? then pattern.pad num, columnPad
      ++num
      x += pitch

    # Pads on the right side
    rowPad.x = distance1 / 2
    y -= pitch
    for i in [1..rowCount]
      rowPad.y = y
      if pins[num]? then pattern.pad num, rowPad
      ++num
      y -= pitch

    # Pads on the top side
    x -= pitch
    columnPad.y = -distance2 / 2
    for i in [1..columnCount]
      columnPad.x = x
      if pins[num]? then pattern.pad num, columnPad
      ++num
      x -= pitch

    @mask pattern

  parsePosition: (value) ->
    values = value.replace(/\s+/g, '').split(',').map((v) => parseFloat(v))
    points = []
    for x in values by 2
      points.push { x: x }
    values.shift()
    for y, i in values by 2
      points[i/2].y = y
    points

  tab: (pattern, element) ->
    housing = element.housing
    hasTab = housing.tabWidth? and housing.tabLength?
    tabNumber = (housing.leadCount ? 2*(housing.rowCount + housing.columnCount)) + 1
    if hasTab
      housing.tabPosition ?= '0, 0'
      points = @parsePosition housing.tabPosition

      for p, i in points
        tabPad =
          type: 'smd'
          shape: 'rectangle'
          width: housing.tabWidth.nom ? housing.tabWidth
          height: housing.tabLength.nom ? housing.tabLength
          layer: ['topCopper', 'topMask', 'topPaste']
          x: p.x
          y: p.y
        pattern.pad tabNumber + i, tabPad

      @mask pattern

    if housing.viaDiameter?
      viaDiameter = housing.viaDiameter
      points = @parsePosition housing.viaPosition
      for p in points
        viaPad =
          type: 'through-hole'
          shape: 'circle'
          drill: viaDiameter
          width: viaDiameter + 0.1
          height: viaDiameter + 0.1
          layer: ['topCopper', 'bottomCopper']
          x: p.x
          y: p.y
        pattern.pad tabNumber, viaPad
