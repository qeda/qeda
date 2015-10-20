module.exports = (pattern, pitch, span, height, pinCount) ->
  pitch /= 100.0
  span /= 100.0
  height /= 100.0
  pinCount *= 1

  housing = pattern.housing
  settings = pattern.settings

  toe = { L: 0.15, N: 0.35, M: 0.55 }
  heel = { L: 0.25, N: 0.35, M: 0.45 }
  side = if pitch > 0.625 then { L: 0.01, N: 0.03, M: 0.05 } else { L: -0.04, N: -0.02, M: 0.01 }
  courtyard = { L: 0.1, N: 0.25, M: 0.5 }

  # Calculation according to IPC-7351
  Lmin = housing.leadSpan.min
  Lmax = housing.leadSpan.max
  Ltol = housing.leadSpan.tol
  Tmax = housing.leadLength.max
  Ttol = housing.leadLength.tol
  Wmin = housing.leadWidth.min

  F = settings.tolerance.fabrication
  P = settings.tolerance.placement
  Jt = toe[settings.densityLevel]
  Jh = heel[settings.densityLevel]
  Js = side[settings.densityLevel]

  Stol = Math.sqrt(Ltol*Ltol + 2*Ttol*Ttol)
  Smin = Lmin - 2*Tmax
  Smax = Smin + Stol

  Cl = Ltol
  Cs = Stol
  Cw = housing.leadWidth.tol
  Zmax = Lmin + 2*Jt + Math.sqrt(Cl*Cl + F*F + P*P)
  Gmin = Smax - 2*Jh - Math.sqrt(Cs*Cs + F*F + P*P)
  Xmax = Wmin + 2*Js + Math.sqrt(Cw*Cw + F*F + P*P)

  padWidth = ((Zmax - Gmin)/2).toFixed(3)
  padHeight = Xmax.toFixed(3)
  padSpace = ((Zmax + Gmin)/2).toFixed(3)

  console.log "#{padWidth}x#{padHeight}, #{padSpace}"

  pad =
    type: 'smd'
    layer: 'top'
    shape: 'oval'
    width: padWidth
    height: padHeight

  # Pads on the left side
  y = -pitch * (pinCount/4 - 0.5)
  num = 1
  for i in [1..pinCount/2]
    pad.name = num++
    pad.x = (-padSpace/2).toFixed(3)
    pad.y = y.toFixed(3)
    pattern.addPad pad
    y += pitch

  # Pads on the right side
  y -= pitch
  for i in [(pinCount/2 + 1)..pinCount]
    pad.name = num++
    pad.x = (padSpace/2).toFixed(3)
    pad.y = y.toFixed(3)
    pattern.addPad pad
    y -= pitch
