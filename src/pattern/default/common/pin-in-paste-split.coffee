log = require '../../../qeda-log'

module.exports = (pattern, pad, holeWidth, holeHeight, options = {}) ->
  return unless pad.type is 'through-hole'

  baseOuterRx = pad.width / 2
  baseOuterRy = pad.height / 2
  baseInnerRx = holeWidth / 2
  baseInnerRy = holeHeight / 2
  return if baseOuterRx <= baseInnerRx or baseOuterRy <= baseInnerRy

  number = (value, fallback) ->
    value = Number value
    if isFinite(value) then value else fallback

  segmentCount = Math.max 1, Math.round(number(options.segments, 2))
  gap = Math.max 0, number(options.gap, 0)
  innerOffset = number options.innerDiameterOffset, 0
  outerOffset = number options.outerDiameterOffset, 0
  layer = options.layer ? ['topPaste']

  # Positive offsets move away from the copper annulus. Thus the inner edge
  # moves towards the hole centre while the outer edge moves away from it.
  radii = ->
    outerRx: baseOuterRx + outerOffset
    outerRy: baseOuterRy + outerOffset
    innerRx: Math.max 0, baseInnerRx - innerOffset
    innerRy: Math.max 0, baseInnerRy - innerOffset

  resolution = Math.pow 10, -(pattern.settings?.decimals ? 3)
  baseThickness = Math.min baseOuterRx - baseInnerRx, baseOuterRy - baseInnerRy
  minimumThickness = Math.min resolution, baseThickness / 2
  isValid = (r) ->
    r.outerRx >= r.innerRx + minimumThickness and
      r.outerRy >= r.innerRy + minimumThickness

  pasteRadii = radii()
  if (innerOffset < 0 or outerOffset < 0) and not isValid(pasteRadii)
    log.error "pinInPasteSplit offsets collapse or invert the paste annulus " +
      "(innerDiameterOffset=#{innerOffset}, outerDiameterOffset=#{outerOffset})"
  return unless isValid pasteRadii

  {outerRx, outerRy, innerRx, innerRy} = pasteRadii
  segmentAngle = Math.PI * 2 / segmentCount
  pointsPerCircle = 32

  # For an ellipse, this is the exact chord length scale around a divider.
  halfGapAngle = (rx, ry, angle) ->
    scale = Math.sqrt(Math.pow(rx * Math.sin(angle), 2) + Math.pow(ry * Math.cos(angle), 2))
    return 0 unless gap > 0 and scale > 0
    halfAngle = Math.asin Math.min(1, gap / (2 * scale))
    minimumArcAngle = Math.min segmentAngle / 2, resolution / Math.max(rx, ry)
    Math.min halfAngle, (segmentAngle - minimumArcAngle) / 2

  addSegment = (index) ->
    nominalStart = -Math.PI / 2 + index * segmentAngle
    nominalEnd = nominalStart + segmentAngle
    outerStart = nominalStart + halfGapAngle(outerRx, outerRy, nominalStart)
    outerEnd = nominalEnd - halfGapAngle(outerRx, outerRy, nominalEnd)
    innerStart = nominalStart + halfGapAngle(innerRx, innerRy, nominalStart)
    innerEnd = nominalEnd - halfGapAngle(innerRx, innerRy, nominalEnd)
    arcAngle = Math.max outerEnd - outerStart, innerEnd - innerStart
    arcSteps = Math.max 2, Math.ceil(pointsPerCircle * arcAngle / (Math.PI * 2))
    points = []
    for i in [0..arcSteps]
      angle = outerStart + (outerEnd - outerStart) * i / arcSteps
      points.push pad.x + Math.cos(angle) * outerRx
      points.push pad.y + Math.sin(angle) * outerRy
    for i in [0..arcSteps]
      angle = innerEnd + (innerStart - innerEnd) * i / arcSteps
      points.push pad.x + Math.cos(angle) * innerRx
      points.push pad.y + Math.sin(angle) * innerRy
    points.push points[0]
    points.push points[1]
    pattern._addShape 'poly',
      points: points
      layer: layer
      lineWidth: 0
      fill: true

  addSegment i for i in [0...segmentCount]
