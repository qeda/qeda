module.exports =
  qfn: (pattern, housing) ->
    params = @_nolead pattern, housing
    params.Lmin = housing.bodyWidth.min
    params.Lmax = housing.bodyWidth.max
    if housing.pullBack?
      params.Lmin -= 2*housing.pullBack
      params.Lmax -= 2*housing.pullBack
    ipc1 = @_ipc7351 params
    params.Lmin = housing.bodyLength.min
    params.Lmax = housing.bodyLength.max
    if housing.pullBack?
      params.Lmin -= 2*housing.pullBack
      params.Lmax -= 2*housing.pullBack
    ipc2 = @_ipc7351 params
    trimmed = false
    pad1 = @_pad ipc1, pattern
    pad2 = @_pad ipc2, pattern

    # Check clearance violations
    settings = pattern.settings
    if pad1.height > housing.pitch - settings.clearance.padToPad
      pad1.height = housing.pitch - settings.clearance.padToPad
      trimmed = true
    if pad2.height > housing.pitch - settings.clearance.padToPad
      pad2.height = housing.pitch - settings.clearance.padToPad
      trimmed = true

    width1: pad1.width
    height1: pad1.height
    distance1: pad1.distance
    width2: pad2.width
    height2: pad2.height
    distance2: pad2.distance
    trimmed: trimmed

  qfp: (pattern, housing) ->
    params = @_gullwing pattern, housing
    params.Lmin = housing.rowSpan.min
    params.Lmax = housing.rowSpan.max
    ipc1 = @_ipc7351 params
    params.Lmin = housing.columnSpan.min
    params.Lmax = housing.columnSpan.max
    ipc2 = @_ipc7351 params
    trimmed = false

    # Trim if pad is under body
    if ipc1.Gmin < (housing.bodyWidth.nom - 0.1) # TODO: determine, why 0.1
      ipc1.Gmin = housing.bodyWidth.nom - 0.1
      trimmed = true
    if ipc2.Gmin < (housing.bodyLength.nom - 0.1)
      ipc2.Gmin = housing.bodyLength.nom - 0.1
      trimmed = true

    pad1 = @_pad ipc1, pattern
    pad2 = @_pad ipc2, pattern

    # Check clearance violations
    settings = pattern.settings
    if pad1.height > housing.pitch - settings.clearance.padToPad
      pad1.height = housing.pitch - settings.clearance.padToPad
      trimmed = true
    if pad2.height > housing.pitch - settings.clearance.padToPad
      pad2.height = housing.pitch - settings.clearance.padToPad
      trimmed = true

    width1: pad1.width
    height1: pad1.height
    distance1: pad1.distance
    width2: pad2.width
    height2: pad2.height
    distance2: pad2.distance
    trimmed: trimmed

  sop: (pattern, housing) ->
    params = @_gullwing pattern, housing
    params.Lmin = housing.leadSpan.min
    params.Lmax = housing.leadSpan.max
    ipc = @_ipc7351 params
    trimmed = false

    # Trim if pad is under body
    if ipc.Gmin < (housing.bodyWidth.nom - 0.1) # TODO: determine, why 0.1
      ipc.Gmin = housing.bodyWidth.nom - 0.1
      trimmed = true

    pad = @_pad ipc, pattern

    # Check clearance violations
    settings = pattern.settings
    if pad.height > housing.pitch - settings.clearance.padToPad
      pad.height = housing.pitch - settings.clearance.padToPad
      trimmed = true

    pad.trimmed = trimmed
    pad

  _gullwing: (pattern, housing) ->
    settings = pattern.settings

    toe = { L: 0.15, N: 0.35, M: 0.55 }
    heel = { L: 0.25, N: 0.35, M: 0.45 }
    side = if housing.pitch > 0.625 then { L: 0.01, N: 0.03, M: 0.05 } else { L: -0.04, N: -0.02, M: 0.01 }

    # Dimensions according to IPC-7351
    Tmin: housing.leadLength.min
    Tmax: housing.leadLength.max
    Wmin: housing.leadWidth.min
    Wmax: housing.leadWidth.max

    F: settings.tolerance.fabrication
    P: settings.tolerance.placement
    Jt: pattern.toe ? toe[settings.densityLevel]
    Jh: pattern.heel ? heel[settings.densityLevel]
    Js: pattern.side ? side[settings.densityLevel]

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
    Tmin: housing.leadLength.min
    Tmax: housing.leadLength.max
    Wmin: housing.leadWidth.min
    Wmax: housing.leadWidth.max

    F: settings.tolerance.fabrication
    P: settings.tolerance.placement
    Jt: pattern.toe ? toe
    Jh: pattern.heel ? heel
    Js: pattern.side ? side

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

    width: padWidth
    height: padHeight
    distance: padDistance
