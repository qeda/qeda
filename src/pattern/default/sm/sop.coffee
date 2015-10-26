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

  # Trim pads when they extend under body
  defaultShape = 'oval'
  if Gmin < housing.bodyWidth.nom
    Gmin = housing.bodyWidth.nom
    defaultShape = 'rectangle'

  sizeRoundoff = settings.roundoff.size
  placeRoundoff = settings.roundoff.place

  padWidth = (Zmax - Gmin) / 2
  padHeight = Xmax
  padDistance = (Zmax + Gmin) / 2

  padWidth    = (Math.ceil( padWidth    / sizeRoundoff ) * sizeRoundoff )
  padHeight   = (Math.ceil( padHeight   / sizeRoundoff ) * sizeRoundoff )
  padDistance = (Math.round(padDistance / placeRoundoff) * placeRoundoff)

  pad =
    type: 'smd'
    width: padWidth
    height: padHeight

  pattern.setLayer 'top'

  # Pads on the left side
  y = -pitch * (pinCount/4 - 0.5)
  num = 1
  for i in [1..pinCount/2]
    pad.name = num++
    pad.x = (-padDistance/2)
    pad.y = y
    pad.shape =  if i is 1 then 'rectangle' else defaultShape
    pattern.addPad pad
    y += pitch

  # Pads on the right side
  y -= pitch
  for i in [(pinCount/2 + 1)..pinCount]
    pad.name = num++
    pad.x = (padDistance/2)
    pad.y = y
    pattern.addPad pad
    y -= pitch

  # Silkscreen
  pattern.setLayer 'topSilkscreen'
  lineWidth = settings.lineWidth.silkscreen
  pattern.setLineWidth lineWidth
  # Rectangle
  rectWidth = housing.bodyWidth.nom
  padSpace = padDistance - padWidth - 2*settings.clearance.padToSilk - lineWidth
  if rectWidth >= padSpace then rectWidth = padSpace
  bodyHeight = housing.bodyLength.nom
  pattern.addRectangle { x: -rectWidth/2, y: -bodyHeight/2, width: rectWidth, height: bodyHeight }
  # First pin keys
  r = 0.25
  x = (-padDistance - padWidth)/2 + r
  y = -pitch*(pinCount/4 - 0.5) - padHeight/2 - r - settings.clearance.padToSilk
  pattern.addCircle { x: x, y: y, radius: r/2, lineWidth: r }
  r = 0.5
  shift = rectWidth/2 - r
  if shift > 0.5 then shift = 0.5
  x = -rectWidth/2 + r + shift
  y = -bodyHeight/2 + r + shift
  pattern.addCircle { x: x, y: y, radius: r/2, lineWidth: r }
  # RefDes
  fontSize = settings.fontSize.refDes
  pattern.addAttribute 'refDes',
    x: 0
    y: -bodyHeight/2 - fontSize/2 - 2*lineWidth
    halign: 'center'
    valign: 'center'

  # Assembly
  pattern.setLayer 'topAssembly'
  pattern.setLineWidth settings.lineWidth.assembly
  bodyWidth = housing.bodyWidth.nom
  leadLength = housing.leadLength.nom
  # Body
  pattern.addRectangle { x: -bodyWidth/2, y: -bodyHeight/2, width: bodyWidth, height: bodyHeight }
  # Pins
  y = -pitch * (pinCount/4 - 0.5)
  num = 1
  for i in [1..pinCount/2]
    pattern.addLine { x1: -bodyWidth/2, y1: y, x2: -bodyWidth/2 - leadLength, y2: y }
    pattern.addLine { x1: bodyWidth/2, y1: y, x2: bodyWidth/2 + leadLength, y2: y }
    y += pitch
  # Key
  r = 0.5
  shift = bodyWidth/2 - r
  if shift > 0.5 then shift = 0.5
  x = -bodyWidth/2 + r + shift
  y = -bodyHeight/2 + r + shift
  pattern.addCircle { x: x, y: y, radius: r}
  # Value
  fontSize = settings.fontSize.value
  pattern.addAttribute 'value',
    text: pattern.name
    x: 0
    y: bodyHeight/2 + fontSize/2 + 0.5
    halign: 'center'
    valign: 'center'
