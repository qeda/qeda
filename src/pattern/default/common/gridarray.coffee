module.exports = (pattern, element, padParams) ->
  rowPitch = padParams.rowPitch
  columnPitch = padParams.columnPitch
  rowCount = padParams.rowCount
  columnCount = padParams.columnCount
  pad = padParams.pad

  gridLetters = element.gridLetters
  pins = element.pins

  # Grid array
  y = -rowPitch * (rowCount/2 - 0.5)
  for row in [1..rowCount]
    x = -columnPitch * (columnCount/2 - 0.5)
    for column in [1..columnCount]
      pad.x = x
      pad.y = y
      pad.name = gridLetters[row] + column
      if pins[pad.name]? # Add only if exists
        pattern.addPad pad
      x += columnPitch
    y += rowPitch
