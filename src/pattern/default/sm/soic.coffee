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
  Tmin = housing.leadLength.min
  Tmax = housing.leadLength.max
  Ttol = housing.leadLength.tol
  Wmin = housing.leadWidth.min
  Wmax = housing.leadWidth.max
  Wtol = housing.leadWidth.tol

  F = settings.tolerance.fabrication
  P = 2*settings.tolerance.placement
  Jt = toe[settings.densityLevel]
  Jh = heel[settings.densityLevel]
  Js = side[settings.densityLevel]

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

  # Trim pads when under body extend
  if Gmin < housing.bodyWidth.nom then Gmin = housing.bodyWidth.nom

  sizeRoundoff = settings.roundoff.size
  placeRoundoff = settings.roundoff.place

  padWidth = (Zmax - Gmin) / 2
  padHeight = Xmax
  padSpace = (Zmax + Gmin) / 2

  padWidth  = (Math.ceil( padWidth   / sizeRoundoff ) * sizeRoundoff ).toFixed(2)
  padHeight = (Math.ceil( padHeight  / sizeRoundoff ) * sizeRoundoff ).toFixed(2)
  padSpace  = (Math.round(padSpace   / placeRoundoff) * placeRoundoff).toFixed(2)

  #console.log pattern.name
  #console.log "#{padWidth}x#{padHeight}, space#{padSpace}"

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
    if i is 1 then pad.shape = 'rectangle'
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
