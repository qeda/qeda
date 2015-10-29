
module.exports =
  calculate: (pattern) ->
    housing = pattern.housing
    settings = pattern.settings

    toe = { L: 0.15, N: 0.35, M: 0.55 }
    heel = { L: 0.25, N: 0.35, M: 0.45 }
    side = if pattern.pitch > 0.625 then { L: 0.01, N: 0.03, M: 0.05 } else { L: -0.04, N: -0.02, M: 0.01 }

    # Calculation according to IPC-7351
    Lmin = housing.leadSpan.min
    Lmax = housing.leadSpan.max
    Ltol = housing.leadSpan.tol
    Tmin = housing.leadLength.min
    Tmax = housing.leadLength.max
    Ttol = housing.leadLength.tol
    Wmin = housing.leadWidth.min
    Wmax = housing.leadWidth.max
    Wtol = housing.leadWidth.tol

    F = settings.tolerance.fabrication
    P = 2*settings.tolerance.placement
    Jt = pattern.toe ? toe[settings.densityLevel]
    Jh = pattern.heel ? heel[settings.densityLevel]
    Js = pattern.side ? side[settings.densityLevel]

    Smin = Lmin - 2*Tmax
    Smax = Lmax - 2*Tmin
    Stol = Ltol + 2*Ttol
    StolRms = Math.sqrt(Ltol*Ltol + 2*Ttol*Ttol)
    SmaxRms = Smax - (Stol - StolRms)/2

    Cl = Ltol
    Cs = StolRms
    Cw = Wtol
    Zmax = Lmin    + 2*Jt + Math.sqrt(Cl*Cl + F*F + P*P)
    Gmin = SmaxRms - 2*Jh - Math.sqrt(Cs*Cs + F*F + P*P)
    Xmax = Wmin    + 2*Js + Math.sqrt(Cw*Cw + F*F + P*P)
    { span: Zmax, gap: Gmin, height: Xmax }

  pad: (dimensions, pattern) ->
    padWidth = (dimensions.span - dimensions.gap) / 2
    padHeight = dimensions.height
    padDistance = (dimensions.span + dimensions.gap) / 2
    sizeRoundoff = pattern.sizeRoundoff ? 0.05
    placeRoundoff = pattern.placeRoundoff ? 0.1
    padWidth    = (Math.ceil( padWidth    / sizeRoundoff ) * sizeRoundoff )
    padHeight   = (Math.ceil( padHeight   / sizeRoundoff ) * sizeRoundoff )
    padDistance = (Math.round(padDistance / placeRoundoff) * placeRoundoff)
    { width: padWidth, height: padHeight, distance: padDistance }
