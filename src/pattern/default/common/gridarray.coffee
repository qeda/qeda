module.exports = (pattern, padParams) ->
  rowPitch = padParams.rowPitch
  columnPitch = padParams.columnPitch
  rowCount = padParams.rowCount
  columnCount = padParams.columnCount

  pad =
    type: 'smd'
    width: padParams.size
    height: padParams.size
    shape: 'circle'
    mask: 0.001 # KiCad does not support zero value
    paste: -0.001 # KiCad does not support zero value

  gridLetters = pattern.element.gridLetters
  pins = pattern.element.pins

  # Pads on the left side
  y = -rowPitch * (rowCount/2 - 0.5)
  for row in [1..rowCount]
    x = -columnPitch * (columnCount/2 - 0.5)
    for column in [1..columnCount]
      pad.x = x
      pad.y = y
      pad.name = gridLetters[row] + column
      if pins[pad.name]?
        pattern.addPad pad
      x += columnPitch
    y += rowPitch
