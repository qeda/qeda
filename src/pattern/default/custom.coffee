assembly = require './common/assembly'
calculator = require './common/calculator'
copper = require './common/copper'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'

pinNumber = 0

copperPads = (pattern, element, suffix = '') ->
  housing = element.housing
  pins = element.pins
  numbers = Object.keys pins
  unless (housing['drillDiameter' + suffix]?) or (housing['padWidth' + suffix]? and housing['padHeight' + suffix]?)
    return false
  hasPads = false
  if housing['drillDiameter' + suffix]?
    drillDiameter = housing['drillDiameter' + suffix]
    padDiameter = calculator.padDiameter pattern, housing, drillDiameter
    padWidth = housing['padWidth' + suffix] ? padDiameter
    padHeight = housing['padHeight' + suffix] ? padDiameter
    pad =
      type: 'through-hole'
      drill: housing['drillDiameter' + suffix]
      width: padWidth
      height: padHeight
      shape: unless pinNumber then 'rectangle' else 'circle'
      layer: ['topCopper', 'topMask', 'topPaste', 'bottomCopper', 'bottomMask', 'bottomPaste']
  else
    pad =
      type: 'smd'
      width: housing['padWidth' + suffix]
      height: housing['padHeight' + suffix]
      shape: 'rectangle'
      layer: ['topCopper', 'topMask', 'topPaste']

  if housing['padPosition' + suffix]?
    hasPads = true
    points = copper.parsePosition housing['padPosition' + suffix]
    for p, i in points
      pad.x = p.x
      pad.y = p.y
      pattern.pad numbers[pinNumber++], pad
      if housing['drillDiameter' + suffix]?
        pad.shape = 'circle'
  else if housing['rowCount' + suffix]? and housing['columnCount' + suffix]?
    hasPads = true
    rowCount = housing['rowCount' + suffix]
    rowPitch = housing['rowPitch' + suffix] ? housing['pitch' + suffix]
    rowDXs = element.parseMultiple housing['rowDX' + suffix]
    rowDYs = element.parseMultiple housing['rowDY' + suffix]
    columnCounts = element.parseMultiple housing['columnCount' + suffix]
    columnPitch = housing['columnPitch' + suffix] ? housing['pitch' + suffix]
    columnDXs = element.parseMultiple housing['columnDX' + suffix]
    columnDYs = element.parseMultiple housing['columnDY' + suffix]
    y = -rowPitch*(rowCount - 1)/2
    for row in [0..(rowCount - 1)]
      columnCount = columnCounts[row] ? columnCounts[0]
      rowDX = rowDXs[row] ? rowDXs[0]
      rowDY = rowDYs[row] ? rowDYs[0]
      x = -columnPitch*(columnCount - 1)/2
      for column in [0..(columnCount - 1)]
        columnDX = columnDXs[row] ? columnDXs[0]
        columnDY = columnDYs[row] ? columnDYs[0]
        pad.x = x + rowDX + columnDX
        pad.y = y + rowDY + columnDY
        pattern.pad numbers[pinNumber++], pad
        if housing['drillDiameter' + suffix]?
          pad.shape = 'circle'
        x += columnPitch
      y += rowPitch

  hasPads

module.exports = (pattern, element) ->
  housing = element.housing
  pattern.name ?= element.name.toUpperCase()

  housing.bodyPosition ?= '0, 0'
  bodyPosition = copper.parsePosition housing.bodyPosition
  pattern.center -bodyPosition[0].x, -bodyPosition[0].y

  pinNumber = 0
  copperPads pattern, element
  i = 1
  loop
    unless copperPads(pattern, element, i++) then break

  pattern.center 0, 0

  copper.mask pattern
  silkscreen.body pattern, housing
  assembly.body pattern, housing
  courtyard.body pattern, housing
