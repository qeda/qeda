assembly = require './common/assembly'
calculator = require './common/calculator'
copper = require './common/copper'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'
log = require '../../qeda-log'

pinNumber = 0
mountingHole = 1
ncPad = 1

addPinInPasteSplit = (pattern, pad, holeWidth, holeHeight, options = {}) ->
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

copperPads = (pattern, element, suffix = '') ->
  housing = element.housing
  pins = element.pins
  pinNumberGroup = 0
  if housing['numbers' + suffix]? then housing['numbers' + suffix] = element.parsePinNumbers housing['numbers' + suffix]
  numbers = housing['numbers' + suffix] ? Object.keys pins
  unless (housing['holeDiameter' + suffix]?) or (housing['padDiameter' + suffix]?) or (housing['padWidth' + suffix]? and housing['padHeight' + suffix]?) or (housing['slotWidth' + suffix]? and housing['slotHeight' + suffix]?)
    return false
  hasPads = false
  splitPasteOptions =
    segments: housing['pinInPasteSplitSegments' + suffix]
    gap: housing['pinInPasteSplitGap' + suffix]
    innerDiameterOffset: housing['pinInPasteSplitInnerDiameterOffset' + suffix]
    outerDiameterOffset: housing['pinInPasteSplitOuterDiameterOffset' + suffix]
    layer: if housing['padBottom' + suffix] then ['bottomPaste'] else ['topPaste']
  addSplitPaste = (pad) ->
    return unless housing['pinInPasteSplit' + suffix]
    if pad.slotWidth? and pad.slotHeight?
      addPinInPasteSplit pattern, pad, pad.slotWidth, pad.slotHeight, splitPasteOptions
    else if pad.hole?
      addPinInPasteSplit pattern, pad, pad.hole, pad.hole, splitPasteOptions

  if housing['slotWidth' + suffix]? and housing['slotHeight' + suffix]?
    slotWidth = housing['slotWidth' + suffix]
    slotHeight = housing['slotHeight' + suffix]
    holeDiameter = if slotWidth > slotHeight then slotWidth else slotHeight
    if slotWidth > slotHeight
      padHeight = housing['padHeight' + suffix] ? calculator.padDiameter pattern, housing, slotHeight
      padWidth = housing['padWidth' + suffix] ? slotWidth + (padHeight - slotHeight)
      padDiameter = housing['padDiameter' + suffix] ? holeDiameter + (padHeight - slotHeight)
    else
      padWidth = housing['padWidth' + suffix] ? calculator.padDiameter pattern, housing, slotWidth
      padHeight = housing['padHeight' + suffix] ? slotHeight + (padWidth - slotWidth)
      padDiameter = housing['padDiameter' + suffix] ? holeDiameter + (padWidth - slotWidth)
    pad =
      type: 'through-hole'
      slotWidth: slotWidth
      slotHeight: slotHeight
      width: padWidth
      height: padHeight
      shape: housing['padShape' + suffix] || (if (pinNumber is 0) and housing.polarized then 'rectangle' else 'circle')
      layer: ['topCopper', 'topMask', 'intCopper', 'bottomCopper', 'bottomMask']
    if (housing['pinInPaste' + suffix]) and not (housing['pinInPasteSplit' + suffix])
      if housing['padBottom' + suffix]
        pad.layer.push('bottomPaste')
      else
        pad.layer.push('topPaste')
    if (padWidth < slotWidth) and (padHeight < slotHeight)
      pad.type = 'mounting-hole'
      pad.layer = ['topMask', 'bottomMask']
      pad.width = slotWidth
      pad.height = slotHeight
      pad.shape = housing['padShape' + suffix] || 'circle'
  else if housing['holeDiameter' + suffix]?
    holeDiameter = housing['holeDiameter' + suffix]
    padDiameter = housing['padDiameter' + suffix] ? calculator.padDiameter pattern, housing, holeDiameter
    padWidth = housing['padWidth' + suffix] ? padDiameter
    padHeight = housing['padHeight' + suffix] ? padDiameter
    pad =
      type: 'through-hole'
      hole: housing['holeDiameter' + suffix]
      width: padWidth
      height: padHeight
      shape: housing['padShape' + suffix] || (if (pinNumber is 0) and housing.polarized then 'rectangle' else 'circle')
      layer: ['topCopper', 'topMask', 'intCopper', 'bottomCopper', 'bottomMask']
    if (housing['pinInPaste' + suffix]) and not (housing['pinInPasteSplit' + suffix])
      if housing['padBottom' + suffix]
        pad.layer.push('bottomPaste')
      else
        pad.layer.push('topPaste')
    if (padWidth < holeDiameter) or (padHeight < holeDiameter)
      pad.type = 'mounting-hole'
      pad.layer = ['topMask', 'bottomMask']
      pad.width = holeDiameter
      pad.height = holeDiameter
      pad.shape = housing['padShape' + suffix] || 'circle'
  else if (housing['padDiameter' + suffix]?) or (housing['padWidth' + suffix]? and housing['padHeight' + suffix]?)
    padDiameter = housing['padDiameter' + suffix]
    padWidth = housing['padWidth' + suffix] ? padDiameter
    padHeight = housing['padHeight' + suffix] ? padDiameter
    if housing.nopaste? or housing['noPaste' + suffix]?
      pad =
        type: 'smd'
        width: padWidth
        height: padHeight
        shape: if padDiameter? then 'circle' else 'rectangle'
        layer: if housing['padBottom' + suffix] then ['bottomCopper', 'bottomMask'] else ['topCopper', 'topMask']
    else
      pad =
        type: 'smd'
        width: padWidth
        height: padHeight
        shape: if padDiameter? then 'circle' else 'rectangle'
        layer: if housing['padBottom' + suffix] then ['bottomCopper', 'bottomMask', 'bottomPaste'] else ['topCopper', 'topMask', 'topPaste']

  if housing['padPosition' + suffix]?
    hasPads = true
    points = pattern.parsePosition housing['padPosition' + suffix]
    for p, i in points
      pad.x = p.x
      pad.y = p.y
      number = if pad.type is 'mounting-hole' then ('MH' + mountingHole++) else ((if housing['numbers' + suffix] then numbers[pinNumberGroup++] else numbers[pinNumber + pinNumberGroup++]) ? ('NC' + ncPad++))
      pattern.pad number, pad
      addSplitPaste pad
      if housing['holeDiameter' + suffix]?
        pad.shape = housing['padShape' + suffix] || 'circle'
  else if housing['rowCount' + suffix]? and housing['columnCount' + suffix]?
    hasPads = true
    rowCount = housing['rowCount' + suffix]
    if rowCount is 1
      verticalPitch = 0
    else
      verticalPitch = housing['verticalPitch' + suffix] ? housing['pitch' + suffix]
    rowDXs = pattern.parseArray housing['rowDX' + suffix]
    rowDYs = pattern.parseArray housing['rowDY' + suffix]
    columnCounts = pattern.parseArray housing['columnCount' + suffix]
    horizontalPitch = housing['horizontalPitch' + suffix] ? housing['pitch' + suffix]
    columnDXs = pattern.parseArray housing['columnDX' + suffix]
    columnDYs = pattern.parseArray housing['columnDY' + suffix]
    y = -verticalPitch*(rowCount - 1)/2
    for row in [0..(rowCount - 1)]
      columnCount = columnCounts[row] ? columnCounts[0]
      rowDX = rowDXs[row] ? rowDXs[0]
      rowDY = rowDYs[row] ? rowDYs[0]
      x = -horizontalPitch*(columnCount - 1)/2
      for column in [0..(columnCount - 1)]
        columnDX = columnDXs[column] ? columnDXs[0]
        columnDY = columnDYs[column] ? columnDYs[0]
        pad.x = x + rowDX + columnDX
        pad.y = y + rowDY + columnDY
        number = if pad.type is 'mounting-hole' then ('MH' + mountingHole++) else ((if housing['numbers' + suffix] then numbers[pinNumberGroup++] else numbers[pinNumber + pinNumberGroup++]) ? ('NC' + ncPad++))
        pattern.pad number, pad
        addSplitPaste pad
        if housing['holeDiameter' + suffix]?
          pad.shape = housing['padShape' + suffix] || 'circle'
        x += horizontalPitch
      y += verticalPitch

  pinNumber += pinNumberGroup
  pinNumberGroup = 0

  hasPads

module.exports = (pattern, element) ->
  housing = element.housing
  pattern.name ?= (element.group || 'custom') + '_' + element.name.toUpperCase()

  housing.bodyPosition ?= '0, 0'
  bodyPosition = pattern.parsePosition housing.bodyPosition
  housing.basePoint ?= '0, 0'
  basePoint = pattern.parsePosition housing.basePoint
  pattern.center -bodyPosition[0].x + basePoint[0].x, -bodyPosition[0].y + basePoint[0].y

  pinNumber = 0
  mountingHole = 1
  ncPad = 1
  copperPads pattern, element
  i = 1
  loop
    unless copperPads(pattern, element, i++) then break

  pattern.center 0, 0

  copper.mask pattern
  silkscreen.body pattern, housing
  if housing.polarized
    assembly.polarized pattern, housing
  else
    assembly.body pattern, housing
  courtyard.boundary pattern, housing
