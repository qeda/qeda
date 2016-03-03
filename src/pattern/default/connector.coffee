sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'

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

  if housing.th # Through hole
    padParams = calculator.throughHole pattern, housing
    pad =
      type: 'through-hole'
      drill: padParams.drill
      width: padParams.diameter
      height: padParams.diameter
      shape: 'circle'
      layer: ['topCopper', 'topMask', 'topPaste', 'bottomCopper', 'bottomMask', 'bottomPaste']
  else
    pad =
      type: 'smd'
      width: housing.padWidth ? 1
      height: housing.padHeight ? 1
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
      x += columnPitch
    y += rowPitch
