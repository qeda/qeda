module.exports = (pattern, padParams) ->
  distance = padParams.distance
  pitch = padParams.pitch
  count = padParams.count
  pad = padParams.pad
  order = padParams.order ? 'round'
  mirror = padParams.mirror ? false
  numbers = switch order
    when 'round'
      [1..count/2].concat(i for i in [count..(count/2 + 1)] by -1)
    when 'rows'
      (i for i in [1..count] by 2).concat(j for j in [2..count] by 2)
    else # 'columns'
      [1..count]

  # Pads on the left side
  pad.x = if mirror then (distance / 2) else (-distance / 2)
  y = -pitch * (count/4 - 0.5)
  for i in [0..(count/2 - 1)]
    pad.name = numbers[i]
    pad.y = y
    pattern.addPad pad
    y += pitch

  # Pads on the right side
  pad.x = if mirror then (-distance / 2) else (distance / 2)
  y = -pitch * (count/4 - 0.5)
  for i in [(count/2)..(count - 1)]
    pad.name = numbers[i]
    pad.y = y
    pattern.addPad pad
    y += pitch
