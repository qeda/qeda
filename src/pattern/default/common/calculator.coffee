module.exports =
  bga: (pattern, housing) ->
    settings = pattern.settings
    # Calculations according to IPC-7351C
    adj = if settings.ball.collapsible then 0.8 else 1
    padSize = housing.leadSize.nom * adj
    roundOff = 0.01
    padSize = Math.round(padSize / roundOff) * roundOff
    courtyard = housing.pitch * 0.8
    roundOff = 0.05
    courtyard = Math.round(courtyard / roundOff) * roundOff

    width: padSize
    height: padSize
    courtyard: courtyard

  chip: (pattern, housing) ->
    housing.leadWidth ?= housing.bodyWidth
    housing.leadSpan ?= housing.bodyLength

    settings = pattern.settings

    height = housing.height.nom ? housing.height
    toe = height * 0.5
    heel = height * 0.1
    side = height * 0.15

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

    courtyard = height * 0.4
    courtyard = Math.round(courtyard / 0.01) * 0.01
    if courtyard > 0.25 then courtyard = 0.25
    pad.courtyard = courtyard
    pad

  melf: (pattern, housing) ->
    settings = pattern.settings

    toe = { L: 0.2, N: 0.4, M: 0.6 }
    heel = { L: 0.02, N: 0.1, M: 0.2 }
    side = { L: 0.01, N: 0.05, M: 0.1 }

    # Dimensions according to IPC-7351
    params = @_params pattern, housing
    params.Jt = pattern.toe ? toe[settings.densityLevel]
    params.Jh = pattern.heel ? heel[settings.densityLevel]
    params.Js = pattern.side ? side[settings.densityLevel]
    params.Lmin = housing.leadSpan.min
    params.Lmax = housing.leadSpan.max

    ipc = @_ipc7351 params
    ipc.clearance = settings.clearance.padToPad
    pad = @_pad ipc, pattern

    pad.courtyard = { L: 0.12, N: 0.25, M: 0.50 }[settings.densityLevel]
    pad

  molded: (pattern, housing) ->
    settings = pattern.settings
    housing.leadWidth ?= housing.bodyWidth
    housing.leadSpan ?= housing.bodyLength

    toe = { L: 0.07, N: 0.15, M: 0.25 }
    heel = { L: 0.2, N: 0.5, M: 0.8 }
    side = { L: -0.1, N: -0.05, M: 0.01 }

    # Dimensions according to IPC-7351
    params = @_params pattern, housing
    params.Jt = pattern.toe ? toe[settings.densityLevel]
    params.Jh = pattern.heel ? heel[settings.densityLevel]
    params.Js = pattern.side ? side[settings.densityLevel]
    params.Lmin = housing.leadSpan.min
    params.Lmax = housing.leadSpan.max

    ipc = @_ipc7351 params
    ipc.clearance = settings.clearance.padToPad
    pad = @_pad ipc, pattern

    pad.courtyard = { L: 0.12, N: 0.25, M: 0.50 }[settings.densityLevel]
    pad

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

    width1: leadPad.width
    height1: leadPad.height
    distance1: leadPad.distance
    width2: tabPad.width
    height2: tabPad.height
    distance2: tabPad.distance
    courtyard: { L: 0.12, N: 0.25, M: 0.50 }[settings.densityLevel]

  qfn: (pattern, housing) ->
    settings = pattern.settings
    params = @_nolead pattern, housing
    params.Lmin = housing.bodyWidth.min
    params.Lmax = housing.bodyWidth.max
    if housing.pullBack?
      params.Lmin -= 2*housing.pullBack
      params.Lmax -= 2*housing.pullBack
    rowIpc = @_ipc7351 params
    params.Lmin = housing.bodyLength.min
    params.Lmax = housing.bodyLength.max
    if housing.pullBack?
      params.Lmin -= 2*housing.pullBack
      params.Lmax -= 2*housing.pullBack
    columnIpc = @_ipc7351 params

    rowIpc.clearance = settings.clearance.padToPad
    rowIpc.pitch = housing.pitch
    rowPad = @_pad rowIpc, pattern

    columnIpc.clearance = settings.clearance.padToPad
    columnIpc.pitch = housing.pitch
    columnPad = @_pad columnIpc, pattern

    width1: rowPad.width
    height1: rowPad.height
    distance1: rowPad.distance
    width2: columnPad.width
    height2: columnPad.height
    distance2: columnPad.distance
    trimmed: rowPad.trimmed or columnPad.trimmed
    courtyard: { L: 0.12, N: 0.25, M: 0.50 }[settings.densityLevel]

  qfp: (pattern, housing) ->
    settings = pattern.settings
    params = @_gullwing pattern, housing
    params.Lmin = housing.rowSpan.min
    params.Lmax = housing.rowSpan.max
    rowIpc = @_ipc7351 params
    params.Lmin = housing.columnSpan.min
    params.Lmax = housing.columnSpan.max
    columnIpc = @_ipc7351 params

    rowIpc.clearance = settings.clearance.padToPad
    rowIpc.pitch = housing.pitch
    rowIpc.body = housing.bodyWidth.nom
    rowPad = @_pad rowIpc, pattern

    columnIpc.clearance = settings.clearance.padToPad
    columnIpc.pitch = housing.pitch
    columnIpc.body = housing.bodyLength.nom
    columnPad = @_pad columnIpc, pattern

    width1: rowPad.width
    height1: rowPad.height
    distance1: rowPad.distance
    width2: columnPad.width
    height2: columnPad.height
    distance2: columnPad.distance
    trimmed: rowPad.trimmed or columnPad.trimmed
    courtyard: { L: 0.12, N: 0.25, M: 0.50 }[settings.densityLevel]

  sop: (pattern, housing) ->
    settings = pattern.settings
    params = @_gullwing pattern, housing
    params.Lmin = housing.leadSpan.min
    params.Lmax = housing.leadSpan.max
    ipc = @_ipc7351 params
    ipc.clearance = settings.clearance.padToPad
    ipc.pitch = housing.pitch
    ipc.body = housing.bodyWidth.nom
    pad = @_pad ipc, pattern

    pad.courtyard = { L: 0.12, N: 0.25, M: 0.50 }[settings.densityLevel];
    pad

  sot: (pattern, housing) ->
    settings = pattern.settings
    housing.leadWidth = housing.leadWidth1
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

    width1: pad1.width
    height1: pad1.height
    distance: pad1.distance
    width2: pad2.width
    height2: pad2.height
    courtyard: { L: 0.12, N: 0.25, M: 0.50 }[settings.densityLevel]
    trimmed: pad1.trimmed or pad2.trimmed

  _gullwing: (pattern, housing) ->
    settings = pattern.settings

    toe = { L: 0.15, N: 0.35, M: 0.55 }
    heel = { L: 0.25, N: 0.35, M: 0.45 }
    side = if housing.pitch > 0.625 then { L: 0.01, N: 0.03, M: 0.05 } else { L: -0.04, N: -0.02, M: 0.01 }

    params = @_params pattern, housing
    params.Jt = pattern.toe ? toe[settings.densityLevel]
    params.Jh = pattern.heel ? heel[settings.densityLevel]
    params.Js = pattern.side ? side[settings.densityLevel]
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

  _nolead: (pattern, housing) ->
    settings = pattern.settings

    toe = if housing.pullBack? then 0.0 else { L: 0.20, N: 0.30, M: 0.40 }[settings.densityLevel]
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
    padWidth    = (Math.round(padWidth    / sizeRoundoff ) * sizeRoundoff )
    padHeight   = (Math.round(padHeight   / sizeRoundoff ) * sizeRoundoff )
    padDistance = (Math.round(padDistance / placeRoundoff) * placeRoundoff)

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
