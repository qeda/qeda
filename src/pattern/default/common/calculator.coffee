module.exports =
  chipArray: (pattern, housing) ->
    settings = pattern.settings
    housing.leadSpan ?= housing.bodyWidth

    toes  = { M:  0.55, N:  0.45, L:  0.35 }
    heels = { M: -0.05, N: -0.07, L: -0.1  }
    sides = { M: -0.05, N: -0.07, L: -0.1  }
    # Dimensions according to IPC-7351
    params = @_params pattern, housing
    params.Jt = pattern.toe ? toes[settings.densityLevel]
    params.Jh = pattern.heel ? heels[settings.densityLevel]
    params.Js = pattern.side ? sides[settings.densityLevel]
    params.Lmin = housing.leadSpan.min
    params.Lmax = housing.leadSpan.max
    ipc = @_ipc7351 params
    ipc.clearance = settings.clearance.padToPad
    ipc.pitch = housing.pitch
    pad = @_pad ipc, pattern

    pad.courtyard = params.courtyard
    pad = @_choosePreferred pad, pattern, housing
    leadToPad = (pad.distance + pad.width - housing.leadSpan.nom) / 2
    if leadToPad < settings.minimum.spaceForIron
      d = settings.minimum.spaceForIron - leadToPad
      pad.width += d
      pad.distance += d
    pad

  cornerConcave: (pattern, housing) ->
    settings = pattern.settings

    outPeriph = { M: 0.35, N: 0.25, L: 0.15 }[settings.densityLevel]
    inPeriph = { M: 0.1, N: 0.0, L: -0.05 }[settings.densityLevel]

    params = @_params pattern, housing

    pad =
      width: params.Tmax + outPeriph + inPeriph
      height: params.Wmax + outPeriph + inPeriph
      distance1: housing.rowSpan.nom - params.Tmax + outPeriph/2 - inPeriph/2
      distance2: housing.columnSpan.nom - params.Wmax + outPeriph/2 - inPeriph/2
      courtyard: params.courtyard

    pad = @_choosePreferred pad, pattern, housing
    leadToPad1 = (pad.distance1 + pad.width - housing.rowSpan.nom) / 2
    leadToPad2 = (pad.distance2 + pad.height - housing.columnSpan.nom) / 2
    if leadToPad1 < settings.minimum.spaceForIron
      d = settings.minimum.spaceForIron - leadToPad1
      pad.width += d
      pad.distance1 += d
    if leadToPad2 < settings.minimum.spaceForIron
      d = settings.minimum.spaceForIron - leadToPad2
      pad.height += d
      pad.distance2 += d
    pad

  dual: (pattern, housing, option) ->
    settings = pattern.settings

    switch option
      when 'flatlead'
        params = @_flatlead pattern, housing
      when 'soj'
        params = @_jlead pattern, housing
      when 'sol'
        params = @_llead pattern, housing
      when 'sop'
        params = @_gullwing pattern, housing

    params.Lmin = housing.leadSpan.min
    params.Lmax = housing.leadSpan.max
    ipc = @_ipc7351 params
    ipc.clearance = settings.clearance.padToPad
    ipc.pitch = housing.pitch
    if option is 'sop'
      ipc.body = housing.bodyWidth.nom
    pad = @_pad ipc, pattern

    pad.courtyard = params.courtyard
    pad = @_choosePreferred pad, pattern, housing
    leadToPad = (pad.distance + pad.width - housing.leadSpan.nom) / 2
    if leadToPad < settings.minimum.spaceForIron
      d = settings.minimum.spaceForIron - leadToPad
      pad.width += d
      pad.distance += d
    pad

  gridArray: (pattern, housing, option) ->
    settings = pattern.settings
    # Calculations according to IPC-7351C
    switch option
      when 'bga'
        adj = if settings.ball.collapsible then 0.8 else 1
        padDiameter = housing.leadDiameter.nom * adj
        roundOff = 0.01
        padDiameter = Math.round(padDiameter / roundOff) * roundOff
        courtyard = housing.pitch * 0.8
        roundOff = 0.05
        courtyard = Math.round(courtyard / roundOff) * roundOff
      when 'cga'
        padDiameter = housing.leadDiameter.nom + 0.1
        pitch = housing.pitch ? Math.min(housing.horizontalPitch, housing.verticalPitch)
        clearance = housing.padSpace ? settings.clearance.padToPad
        if padDiameter > pitch - clearance
          padDiameter = pitch - clearance
        courtyard = 1
      when 'lga'
        clearance = housing.padSpace ? settings.clearance.padToPad

        padWidth = housing.leadLength.nom + 0.1
        horizontalPitch = housing.horizontalPitch ? housing.pitch
        if padWidth > horizontalPitch - clearance
          padWidth = horizontalPitch - clearance

        padHeight = housing.leadWidth.nom + 0.1
        verticalPitch = housing.verticalPitch ? housing.pitch
        if padHeight > verticalPitch - clearance
          padHeight = verticalPitch - clearance

        courtyard = 1

    padWidth ?= padDiameter
    padHeight ?= padDiameter

    pad =
      width: padWidth
      height: padHeight
      courtyard: courtyard
    @_choosePreferred pad, pattern, housing

  padDiameter: (pattern, housing, holeDiameter) ->
    settings = pattern.settings
    padDiameter = holeDiameter * settings.ratio.padToHole
    if padDiameter < (holeDiameter + 2*settings.minimum.ringWidth)
      padDiameter = holeDiameter + 2*settings.minimum.ringWidth
    if housing.pitch? or (housing.horizontalPitch? and housing.verticalPitch?)
      pitch = housing.pitch ? Math.min(Math.abs(housing.horizontalPitch), Math.abs(housing.verticalPitch))
      clearance = housing.padSpace ? settings.clearance.padToPad
      if padDiameter > pitch - clearance
        padDiameter = pitch - clearance

    sizeRoundoff = pattern.sizeRoundoff ? 0.05
    Math.round(padDiameter/sizeRoundoff) * sizeRoundoff

  pak: (pattern, housing) ->
    settings = pattern.settings
    params = @_gullwing pattern, housing
    params.Lmin = housing.leadSpan.min
    params.Lmax = housing.leadSpan.max
    leadIpc = @_ipc7351 params
    leadIpc.clearance = settings.clearance.padToPad
    leadIpc.pitch = housing.pitch
    leadPad = @_pad leadIpc, pattern

    params.Tmin = housing.tabLength.min ? housing.tabLength
    params.Tmax = housing.tabLength.max ? housing.tabLength
    params.Wmin = housing.tabWidth.min ? housing.tabWidth
    params.Wmax = housing.tabWidth.max ? housing.tabWidth
    tabIpc = @_ipc7351 params
    tabPad = @_pad tabIpc, pattern

    pad =
      width1: leadPad.width
      height1: leadPad.height
      distance1: leadPad.distance
      width2: tabPad.width
      height2: tabPad.height
      distance2: tabPad.distance
      courtyard: params.courtyard
    pad = @_choosePreferred pad, pattern, housing
    leadToPad1 = (pad.distance1 + pad.width1 - housing.leadSpan.nom) / 2
    leadToPad2 = (pad.distance2 + pad.width2 - housing.leadSpan.nom) / 2
    if leadToPad1 < settings.minimum.spaceForIron
      d = settings.minimum.spaceForIron - leadToPad1
      pad.width1 += d
      pad.distance1 += d
    if leadToPad2 < settings.minimum.spaceForIron
      d = settings.minimum.spaceForIron - leadToPad2
      pad.width2 += d
      pad.distance2 += d
    pad

  quad: (pattern, housing, option) ->
    settings = pattern.settings
    switch option
      when 'qfn'
        params = @_nolead pattern, housing
        params.Lmin = housing.bodyWidth.min
        params.Lmax = housing.bodyWidth.max
        if housing.pullBack?
          params.Lmin -= 2*housing.pullBack.nom
          params.Lmax -= 2*housing.pullBack.nom
        rowIpc = @_ipc7351 params
        params.Lmin = housing.bodyLength.min
        params.Lmax = housing.bodyLength.max
        if housing.pullBack?
          params.Lmin -= 2*housing.pullBack.nom
          params.Lmax -= 2*housing.pullBack.nom
        columnIpc = @_ipc7351 params
        rowSpan = housing.bodyWidth.nom
        columnSpan = housing.bodyLength.nom
      when 'qfp'
        params = @_gullwing pattern, housing
        params.Lmin = housing.rowSpan.min
        params.Lmax = housing.rowSpan.max
        rowIpc = @_ipc7351 params
        params.Lmin = housing.columnSpan.min
        params.Lmax = housing.columnSpan.max
        columnIpc = @_ipc7351 params
        rowSpan = housing.rowSpan.nom
        columnSpan = housing.columnSpan.nom

    rowIpc.clearance = settings.clearance.padToPad
    rowIpc.pitch = housing.pitch
    if option is 'qfp' then rowIpc.body = housing.bodyWidth.nom
    rowPad = @_pad rowIpc, pattern

    columnIpc.clearance = settings.clearance.padToPad
    columnIpc.pitch = housing.pitch
    if option is 'qfp' then columnIpc.body = housing.bodyLength.nom
    columnPad = @_pad columnIpc, pattern

    pad =
      width1: rowPad.width
      height1: rowPad.height
      distance1: rowPad.distance
      width2: columnPad.width
      height2: columnPad.height
      distance2: columnPad.distance
      trimmed: rowPad.trimmed or columnPad.trimmed
      courtyard: params.courtyard
    pad = @_choosePreferred pad, pattern, housing
    leadToPad1 = (pad.distance1 + pad.width1 - rowSpan) / 2
    leadToPad2 = (pad.distance2 + pad.width2 - columnSpan) / 2
    if leadToPad1 < settings.minimum.spaceForIron
      d = settings.minimum.spaceForIron - leadToPad1
      pad.width1 += d
      pad.distance1 += d
      leadToPad1 = (pad.distance1 + pad.width1 - rowSpan) / 2
    if leadToPad2 < settings.minimum.spaceForIron
      d = settings.minimum.spaceForIron - leadToPad2
      pad.width2 += d
      pad.distance2 += d
    pad

  son: (pattern, housing) ->
    settings = pattern.settings

    params = @_nolead pattern, housing
    params.Lmin = housing.bodyWidth.min
    params.Lmax = housing.bodyWidth.max
    if housing.pullBack?
      params.Lmin -= 2*housing.pullBack.nom
      params.Lmax -= 2*housing.pullBack.nom

    ipc = @_ipc7351 params
    ipc.clearance = settings.clearance.padToPad
    ipc.pitch = housing.pitch
    pad = @_pad ipc, pattern
    if housing.leadLength1?
      dw = housing.leadLength1.nom - housing.leadLength.nom
      space = pad.distance - pad.width
      if (space - dw) < settings.clearance.padToPad
        dw = space - settings.clearance.padToPad
      pad.width1 = pad.width + dw

    pad.courtyard = params.courtyard
    pad = @_choosePreferred pad, pattern, housing
    leadToPad = (pad.distance + pad.width - housing.bodyWidth.nom) / 2
    if leadToPad < settings.minimum.spaceForIron
      d = settings.minimum.spaceForIron - leadToPad
      pad.width += d
      pad.distance += d
    pad

  sot: (pattern, housing) ->
    settings = pattern.settings
    housing.leadWidth = housing.leadWidth1

    if housing.flatlead
      params = @_flatlead pattern, housing
    else
      params = @_gullwing pattern, housing

    params.Lmin = housing.leadSpan.min
    params.Lmax = housing.leadSpan.max
    params.body = housing.bodyWidth
    ipc1 = @_ipc7351 params
    ipc1.clearance = settings.clearance.padToPad
    ipc1.pitch = housing.pitch
    ipc1.body = housing.bodyWidth.nom
    pad1 = @_pad ipc1, pattern, housing.pitch
    params.Wmin = housing.leadWidth2.min
    params.Wmax = housing.leadWidth2.max
    ipc2 = @_ipc7351 params
    ipc2.body = housing.bodyWidth.nom
    pad2 = @_pad ipc2, pattern

    pad =
      width1: pad1.width
      height1: pad1.height
      distance: pad1.distance
      width2: pad2.width
      height2: pad2.height
      courtyard: params.courtyard
      trimmed: pad1.trimmed or pad2.trimmed
    pad = @_choosePreferred pad, pattern, housing
    leadToPad = (pad.distance + pad.width1/2 + pad.width2/2 - housing.leadSpan.nom) / 2
    if leadToPad < settings.minimum.spaceForIron
      d = settings.minimum.spaceForIron - leadToPad
      pad.width1 += d
      pad.width2 += d
      pad.distance += d
    pad

  throughHole: (pattern, housing) ->
    settings = pattern.settings

    if housing.leadDiameter?
      diameter = housing.leadDiameter.max
    else
      w = housing.leadWidth.max
      h = housing.leadHeight.max
      diameter = Math.sqrt(w*w + h*h) # Pythagorean theorem
    hole = diameter + 2*settings.clearance.leadToHole
    if hole < settings.minimum.holeDiameter then hole = settings.minimum.holeDiameter
    sizeRoundoff = pattern.sizeRoundoff ? 0.05
    hole = Math.ceil(hole / sizeRoundoff ) * sizeRoundoff
    padDiameter = @padDiameter pattern, housing, hole

    pad =
      hole: hole
      width: padDiameter
      height: padDiameter
    @_choosePreferred pad, pattern, housing

  twoPin: (pattern, housing, option = 'chip') ->
    unless option is 'radial'
      housing.bodyWidth ?= housing.bodyDiameter
      housing.leadWidth ?= housing.bodyWidth
      housing.leadSpan ?= housing.bodyLength

    settings = pattern.settings

    switch option
      when 'chip'
        height = housing.height.nom ? housing.height
        toe = height * 0.5
        heel = height * 0.1
        side = height * 0.15
        courtyard = height * 0.4
        courtyard = Math.round(courtyard / 0.01) * 0.01
        if courtyard > 0.25 then courtyard = 0.25
      when 'concave'
        toes =       { M:  0.55, N:  0.45, L:  0.35 }
        heels =      { M: -0.05, N: -0.07, L: -0.1  }
        sides =      { M: -0.05, N: -0.07, L: -0.1  }
      when 'crystal'
        toes =  if height >= 10 then { M: 1,   N:  0.7,  L:  0.4,}  else { M: 0.7, N:  0.5, L:  0.3 }
        heels = if height >= 10 then { M: 0,   N: -0.05, L: -0.1 }  else { M: 0,   N: -0.1, L: -0.2 }
        sides = if height >= 10 then { M: 0.6, N:  0.5,  L:  0.4 }  else { M: 0.5, N:  0.4, L:  0.3 }
        courtyard = { M: 1, N: 0.5, L: 0.25 }[settings.densityLevel]
      when 'dfn'
        toes =       { M: 0.6, N: 0.4,  L: 0.2 }
        heels =      { M: 0.2, N: 0.1,  L: 0.02}
        sides =      { M: 0.1, N: 0.05, L: 0.01 }
      when 'melf'
        toes =       { M: 0.6, N: 0.4,  L: 0.2  }
        heels =      { M: 0.2, N: 0.1,  L: 0.02 }
        sides =      { M: 0.1, N: 0.05, L: 0.01 }
      when 'molded'
        toes =       { M: 0.25, N:  0.15, L:  0.07 }
        heels =      { M: 0.8,  N:  0.5,  L:  0.2  }
        sides =      { M: 0.01, N: -0.05, L: -0.1  }
      when 'radial'
        pad = @throughHole pattern, housing
        pad.distance = housing.leadSpan.nom
        pad.courtyard = { M: 0.5, N: 0.25, L: 0.12 }[settings.densityLevel]
        return pad
      when 'sod'
        toes =       { M: 0.55, N: 0.35, L: 0.15 }
        heels =      { M: 0.45, N: 0.35, L: 0.25 }
        sides =      { M: 0.05, N: 0.03, L: 0.01 }
      when 'sodfl'
        toes =       { M: 0.3,  N: 0.2,  L:  0.1  }
        heels =      { M: 0,    N: 0,    L:  0    }
        sides =      { M: 0.05, N: 0,    L: -0.05 }
        courtyard =  { M: 0.2,  N: 0.15, L:  0.12 }[settings.densityLevel]

    toe ?= toes[settings.densityLevel]
    heel ?= heels[settings.densityLevel]
    side ?= sides[settings.densityLevel]

    # Dimensions according to IPC-7351
    params = @_params pattern, housing
    params.Jt = pattern.toe ? toe
    params.Jh = pattern.heel ? heel
    params.Js = pattern.side ? side
    params.Lmin = housing.leadSpan.min
    params.Lmax = housing.leadSpan.max

    ipc = @_ipc7351 params
    ipc.clearance = settings.clearance.padToPad
    pad = @_pad ipc, pattern

    pad.courtyard = courtyard ? params.courtyard
    pad = @_choosePreferred pad, pattern, housing
    leadToPad = (pad.distance + pad.width - housing.leadSpan.nom) / 2
    if leadToPad < settings.minimum.spaceForIron
      d = settings.minimum.spaceForIron - leadToPad
      pad.width += d
      pad.distance += d
    pad

  _choosePreferred: (pad, pattern, housing) ->
    settings = pattern.settings
    if settings.preferManufacturer
      if housing.padWidth?
        pad.width = housing.padWidth
        if housing.padSpace? then pad.distance = housing.padSpace + housing.padWidth
        if housing.padSpace1? then pad.distance1 = housing.padSpace1 + housing.padWidth
        if housing.padSpan? then pad.distance = housing.padSpan - housing.padWidth
        if housing.padSpan1? then pad.distance1 = housing.padSpan1 - housing.padWidth
      if housing.padWidth1?
        pad.width1 = housing.padWidth1
        if housing.padSpace? then pad.distance1 = housing.padSpace + housing.padWidth1
        if housing.padSpace1? then pad.distance1 = housing.padSpace1 + housing.padWidth1
        if housing.padSpan? then pad.distance1 = housing.padSpan - housing.padWidth1
        if housing.padSpan1? then pad.distance1 = housing.padSpan1 - housing.padWidth1
      if housing.padWidth2?
        pad.width2 = housing.padWidth2
        if housing.padSpace? then pad.distance2 = housing.padSpace + housing.padWidth2
        if housing.padSpace2? then pad.distance2 = housing.padSpace2 + housing.padWidth2
        if housing.padSpan? then pad.distance2 = housing.padSpan - housing.padWidth2
        if housing.padSpan2? then pad.distance2 = housing.padSpan2 - housing.padWidth2

      if housing.padHeight?
        pad.height = housing.padHeight
        if housing.padSpace2? then pad.distance2 = housing.padSpace2 + housing.padHeight
        if housing.padSpan2? then pad.distance2 = housing.padSpan2 - housing.padHeight

      if housing.padHeight1? then pad.height1 = housing.padHeight1
      if housing.padHeight2? then pad.height2 = housing.padHeight2

      if housing.padDistance? then pad.distance = housing.padDistance
      if housing.padDistance1? then pad.distance1 = housing.padDistance1
      if housing.padDistance2? then pad.distance2 = housing.padDistance2

      if housing.holeDiameter? then pad.hole = housing.holeDiameter
    pad

  _gullwing: (pattern, housing) ->
    settings = pattern.settings

    toes =  { M: 0.55, N: 0.35, L: 0.15 }
    heels = { M: 0.45, N: 0.35, L: 0.25 }
    sides = if housing.pitch > 0.625 then { M: 0.05, N: 0.03, L: 0.01 } else { M: 0.01, N: -0.02, L: -0.04 }

    params = @_params pattern, housing
    params.Jt = pattern.toe ? toes[settings.densityLevel]
    params.Jh = pattern.heel ? heels[settings.densityLevel]
    params.Js = pattern.side ? sides[settings.densityLevel]
    params

  _flatlead: (pattern, housing) ->
    settings = pattern.settings

    toes =  { M: 0.3,  N: 0.2, L: 0.1   }
    heels = { M: 0,    N: 0,   L: 0     }
    sides = { M: 0.05, N: 0,   L: -0.05 }

    params = @_params pattern, housing
    params.Jt = pattern.toe ? toes[settings.densityLevel]
    params.Jh = pattern.heel ? heels[settings.densityLevel]
    params.Js = pattern.side ? sides[settings.densityLevel]
    params

  _ipc7351: (params) ->
    # Calculation according to IPC-7351
    Lmin = params.Lmin
    Lmax = params.Lmax
    Ltol = Lmax - Lmin
    Tmin = params.Tmin
    Tmax = params.Tmax
    Ttol = Tmax - Tmin
    Wmin = params.Wmin
    Wmax = params.Wmax
    Wtol = Wmax - Wmin

    F = params.F
    P = params.P
    Jt = params.Jt
    Jh = params.Jh
    Js = params.Js

    Smin = Lmin - 2*Tmax
    Smax = Lmax - 2*Tmin
    Stol = Ltol + 2*Ttol
    StolRms = Math.sqrt(Ltol*Ltol + 2*Ttol*Ttol)
    SmaxRms = Smax - (Stol - StolRms)/2

    Cl = Ltol
    Cs = StolRms
    Cw = Wtol

    Zmax: Lmin    + 2*Jt + Math.sqrt(Cl*Cl + F*F + P*P)
    Gmin: SmaxRms - 2*Jh - Math.sqrt(Cs*Cs + F*F + P*P)
    Xmax: Wmin    + 2*Js + Math.sqrt(Cw*Cw + F*F + P*P)

  _jlead: (pattern, housing) ->
    settings = pattern.settings

    toes =  { M: 0.1,  N: 0,    L: -0.1  }
    heels = { M: 0.55, N: 0.35, L:  0.15 }
    sides = { M: 0.05, N: 0.03, L:  0.01 }

    params = @_params pattern, housing
    params.Jt = pattern.heel ? heels[settings.densityLevel] # Heel and toe are ...
    params.Jh = pattern.toe ? toes[settings.densityLevel]   # ... swapped for J-Lead
    params.Js = pattern.side ? sides[settings.densityLevel]
    params

  _llead: (pattern, housing) ->
    settings = pattern.settings

    toes =  { M: 0.1,  N:  0,    L: -0.1  }
    heels = { M: 0.55, N:  0.35, L:  0.15 }
    sides = { M: 0.01, N: -0.02, L: -0.04 }

    params = @_params pattern, housing
    params.Jt = pattern.heel ? heels[settings.densityLevel] # Heel and toe are ...
    params.Jh = pattern.toe ? toes[settings.densityLevel]   # ... swapped for L-Lead
    params.Js = pattern.side ? sides[settings.densityLevel]
    params

  _nolead: (pattern, housing) ->
    settings = pattern.settings

    toe = if housing.pullBack? then 0.0 else { M: 0.4, N: 0.3, L: 0.2 }[settings.densityLevel]
    heel = 0.0
    side = if housing.pullBack? then 0.0 else -0.04

    # Dimensions according to IPC-7351
    params = @_params pattern, housing
    params.Jt = pattern.toe ? toe
    params.Jh = pattern.heel ? heel
    params.Js = pattern.side ? side
    params

  _pad: (ipc, pattern) ->
    padWidth = (ipc.Zmax - ipc.Gmin) / 2
    padHeight = ipc.Xmax
    padDistance = (ipc.Zmax + ipc.Gmin) / 2

    # Round off
    sizeRoundoff = pattern.sizeRoundoff ? 0.05
    placeRoundoff = pattern.placeRoundoff ? 0.1
    padWidth    = Math.round(padWidth    / sizeRoundoff ) * sizeRoundoff
    padHeight   = Math.round(padHeight   / sizeRoundoff ) * sizeRoundoff
    padDistance = Math.round(padDistance / placeRoundoff) * placeRoundoff

    # Check clearance violations
    gap = padDistance - padWidth
    span = padDistance + padWidth
    trimmed = false

    if ipc.clearance? and gap < ipc.clearance
      gap = ipc.clearance
      trimmed = true

    # Trim if pad is under body
    if ipc.body? and gap < (ipc.body - 0.1) # TODO: determine, why 0.1
      gap = ipc.body - 0.1
      trimmed = true

    if trimmed
      padWidth = (span - gap) / 2
      padDistance = (span + gap) / 2
      padDistance = (Math.ceil(padDistance / placeRoundoff) * placeRoundoff)

    # Pad height should not violate clearance rules
    if ipc.pitch? and padHeight > (ipc.pitch - ipc.clearance)
      padHeight = ipc.pitch - ipc.clearance
      trimmed = true

    width: padWidth
    height: padHeight
    distance: padDistance
    trimmed: trimmed

  _params: (pattern, housing) ->
    settings = pattern.settings
    # Dimensions according to IPC-7351
    Tmin: housing.leadLength.min
    Tmax: housing.leadLength.max
    Wmin: housing.leadWidth.min
    Wmax: housing.leadWidth.max

    F: settings.tolerance.fabrication
    P: settings.tolerance.placement

    courtyard: pattern.courtyard ? { M: 0.5, N: 0.25, L: 0.12 }[settings.densityLevel]
