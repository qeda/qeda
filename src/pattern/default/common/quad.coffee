module.exports = (pattern, padParams) ->
  padWidth1 = padParams.width1
  padHeight1 = padParams.height1
  padDistance1 = padParams.distance1

  padWidth2 = padParams.width2
  padHeight2 = padParams.height2
  padDistance2 = padParams.distance2

  defaultShape = padParams.defaultShape

  pitch = padParams.pitch
  leadCount1 = padParams.count1
  leadCount2 = padParams.count2

  pad1 =
    type: 'smd'
    width: padWidth1
    height: padHeight1

  # Rotated to 90 degree (swap width and height)
  pad2 =
    type: 'smd'
    width: padHeight2
    height: padWidth2
    shape: defaultShape

  # Pads on the left side
  pad1.x = -padDistance1 / 2
  y = -pitch * (leadCount1/2 - 0.5)
  num = 1
  for i in [1..leadCount1]
    pad1.name = num++
    pad1.y = y
    pad1.shape =  if i is 1 then 'rectangle' else defaultShape
    pattern.addPad pad1
    y += pitch

  # Pads on the bottom side
  x = -pitch * (leadCount2/2 - 0.5)
  pad2.y = padDistance2 / 2
  for i in [1..leadCount2]
    pad2.name = num++
    pad2.x = x
    pattern.addPad pad2
    x += pitch

  # Pads on the right side
  pad1.x = padDistance1 / 2
  y -= pitch
  for i in [1..leadCount1]
    pad1.name = num++
    pad1.y = y
    pattern.addPad pad1
    y -= pitch

  # Pads on the top side
  x -= pitch
  pad2.y = -padDistance2 / 2
  for i in [1..leadCount2]
    pad2.name = num++
    pad2.x = x
    pattern.addPad pad2
    x -= pitch
