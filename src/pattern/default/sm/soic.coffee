module.exports = (pattern, pitch, span, height, pinCount) ->
  pitch /= 100.0
  span /= 100.0
  height /= 100.0
  pinCount *= 1

  pad =
    type: 'smd'
    layer: 'top'
    shape: 'oval'
    width: 5
    height: 1

  # Pads on the left side
  y = 0
  num = 1
  for i in [1..pinCount/2]
    pad.name = num++
    pad.x = 0
    pad.y = y
    pattern.addPad pad
    y += pitch

  # Pads on the right side
  y -= pitch
  for i in [(pinCount/2 + 1)..pinCount]
    pad.name = num++
    pad.x = 10
    pad.y = y
    pattern.addPad pad
    y -= pitch
