sprintf = require('sprintf-js').sprintf

assembly = require './common/assembly'
calculator = require './common/calculator'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  leadCount = housing.rowCount*housing.columnCount

  pattern.name ?= sprintf "CON%02dP%dX%dX%d-%d%s",
    [housing.pitch*100
    housing.bodyLength.nom*10
    housing.bodyWidth.nom*10
    housing.height.max*10
    leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  rowPitch = housing.rowPitch ? housing.pitch
  columnPitch = housing.columnPitch ? housing.pitch
  rowCount = housing.rowCount
  columnCount = housing.columnCount
  throughHole = housing.holeDiameter? or housing.th

  if throughHole
    padParams = calculator.throughHole pattern, housing
    pad =
      type: 'through-hole'
      hole: housing.holeDiameter ? padParams.hole
      width: housing.padWidth ? padParams.diameter
      height: housing.padHeight ? padParams.diameter
      shape: 'rectangle'
      layer: ['topCopper', 'topMask', 'topPaste', 'bottomCopper', 'bottomMask', 'bottomPaste']
  else
    pad =
      type: 'smd'
      width: housing.padWidth
      height: housing.padHeight
      shape: 'rectangle'
      layer: ['topCopper', 'topMask', 'topPaste']

  num = 1
  y = -rowPitch * (rowCount/2 - 0.5)
  for row in [1..rowCount]
    x = -columnPitch * (columnCount/2 - 0.5)
    for column in [1..columnCount]
      pad.x = x
      pad.y = y
      pattern.pad num++, pad
      if throughHole then pad.shape = 'circle'
      x += columnPitch
    y += rowPitch

  silkscreen.connector pattern, housing
  assembly.polarized pattern, housing
  courtyard.connector pattern, housing, 1
