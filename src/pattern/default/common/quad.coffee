module.exports = (pattern, padParams) ->
  pitch = padParams.pitch
  rowCount = padParams.rowCount
  columnCount = padParams.columnCount
  rowPad = padParams.rowPad
  columnPad = padParams.columnPad
  distance1 = padParams.distance1
  distance2 = padParams.distance2

  # Pads on the left side
  rowPad.x = -distance1 / 2
  y = -pitch * (rowCount/2 - 0.5)
  num = 1
  for i in [1..rowCount]
    rowPad.name = num++
    rowPad.y = y
    pattern.addPad rowPad
    y += pitch

  # Pads on the bottom side
  x = -pitch * (columnCount/2 - 0.5)
  columnPad.y = distance2 / 2
  for i in [1..columnCount]
    columnPad.name = num++
    columnPad.x = x
    pattern.addPad columnPad
    x += pitch

  # Pads on the right side
  rowPad.x = distance1 / 2
  y -= pitch
  for i in [1..rowCount]
    rowPad.name = num++
    rowPad.y = y
    pattern.addPad rowPad
    y -= pitch

  # Pads on the top side
  x -= pitch
  columnPad.y = -distance2 / 2
  for i in [1..columnCount]
    columnPad.name = num++
    columnPad.x = x
    pattern.addPad columnPad
    x -= pitch
