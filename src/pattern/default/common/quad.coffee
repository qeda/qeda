module.exports = (pattern, padParams) ->
  padWidth1 = padParams.width1
  padHeight1 = padParams.height1
  padDistance1 = padParams.distance1

  padWidth2 = padParams.width2
  padHeight2 = padParams.height2
  padDistance2 = padParams.distance2

  pitch = padParams.pitch
  rowCount = padParams.rowCount
  columnCount = padParams.columnCount

  rowPad =
    type: 'smd'
    width: padWidth1
    height: padHeight1
    shape: 'rectangle'

  # Rotated to 90 degree (swap width and height)
  columnPad =
    type: 'smd'
    width: padHeight2
    height: padWidth2
    shape: 'rectangle'

  # Pads on the left side
  rowPad.x = -padDistance1 / 2
  y = -pitch * (rowCount/2 - 0.5)
  num = 1
  for i in [1..rowCount]
    rowPad.name = num++
    rowPad.y = y
    pattern.addPad rowPad
    y += pitch

  # Pads on the bottom side
  x = -pitch * (columnCount/2 - 0.5)
  columnPad.y = padDistance2 / 2
  for i in [1..columnCount]
    columnPad.name = num++
    columnPad.x = x
    pattern.addPad columnPad
    x += pitch

  # Pads on the right side
  rowPad.x = padDistance1 / 2
  y -= pitch
  for i in [1..rowCount]
    rowPad.name = num++
    rowPad.y = y
    pattern.addPad rowPad
    y -= pitch

  # Pads on the top side
  x -= pitch
  columnPad.y = -padDistance2 / 2
  for i in [1..columnCount]
    columnPad.name = num++
    columnPad.x = x
    pattern.addPad columnPad
    x -= pitch
