module.exports =
  qfn: (pattern, housing) ->
    params = @_nolead pattern, housing
    params.Lmin = housing.bodyWidth.min
    params.Lmax = housing.bodyWidth.max
    ipc1 = @_ipc7351 params
    params.Lmin = housing.bodyLength.min
    params.Lmax = housing.bodyLength.max
    ipc2 = @_ipc7351 params
    trimmed = false
    # TODO: Trim
    pad1 = @_pad ipc1, pattern
    pad2 = @_pad ipc2, pattern

    width1: pad1.width
    height1: pad1.height
    distance1: pad1.distance
    width2: pad2.width
    height2: pad2.height
    distance2: pad2.distance
    trimmed: trimmed

  qfp: (pattern, housing) ->
    params = @_gullwing pattern, housing
    params.Lmin = housing.leadSpan1.min
    params.Lmax = housing.leadSpan1.max
    ipc1 = @_ipc7351 params
    params.Lmin = housing.leadSpan2.min
    params.Lmax = housing.leadSpan2.max
    ipc2 = @_ipc7351 params
    trimmed = false
    if ipc1.Gmin < housing.bodyWidth.nom
      ipc1.Gmin = housing.bodyWidth.nom
      trimmed = true
    if ipc2.Gmin < housing.bodyLength.nom
      ipc2.Gmin = housing.bodyLength.nom
      trimmed = true
    pad1 = @_pad ipc1, pattern
    pad2 = @_pad ipc2, pattern

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
    if ipc.Gmin < housing.bodyWidth.nom
      ipc.Gmin = housing.bodyWidth.nom
      trimmed = true
      defaultShape = 'rectangle'
    pad = @_pad ipc, pattern
    pad.trimmed = trimmed
    pad

  _gullwing: (pattern, housing) ->
    settings = pattern.settings

    toe = { L: 0.15, N: 0.35, M: 0.55 }
    heel = { L: 0.25, N: 0.35, M: 0.45 }
    side = if pattern.pitch > 0.625 then { L: 0.01, N: 0.03, M: 0.05 } else { L: -0.04, N: -0.02, M: 0.01 }

    # Dimensions according to IPC-7351
    Tmin: housing.leadLength.min
    Tmax: housing.leadLength.max
    Wmin: housing.leadWidth.min
    Wmax: housing.leadWidth.max

    F: settings.tolerance.fabrication
    P: 2*settings.tolerance.placement
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

    toe = { L: 0.20, N: 0.30, M: 0.40 }

    # Dimensions according to IPC-7351
    Tmin: housing.leadLength.min
    Tmax: housing.leadLength.max
    Wmin: housing.leadWidth.min
    Wmax: housing.leadWidth.max

    F: settings.tolerance.fabrication
    P: 2*settings.tolerance.placement
    Jt: pattern.toe ? toe[settings.densityLevel]
    Jh: pattern.heel ? 0.00
    Js: pattern.side ? -0.04

  _pad: (ipc, pattern) ->
    padWidth = (ipc.Zmax - ipc.Gmin) / 2
    padHeight = ipc.Xmax
    padDistance = (ipc.Zmax + ipc.Gmin) / 2
    sizeRoundoff = pattern.sizeRoundoff ? 0.05
    placeRoundoff = pattern.placeRoundoff ? 0.1
    padWidth    = (Math.ceil( padWidth    / sizeRoundoff ) * sizeRoundoff )
    padHeight   = (Math.ceil( padHeight   / sizeRoundoff ) * sizeRoundoff )
    padDistance = (Math.round(padDistance / placeRoundoff) * placeRoundoff)

    width: padWidth
    height: padHeight
    distance: padDistance
