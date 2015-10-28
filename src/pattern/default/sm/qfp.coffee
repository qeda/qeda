module.exports = (pattern, pitch, span1, span2, height, pinCount) ->
  pitch /= 100.0
  span1 /= 100.0
  span2 /= 100.0
  height /= 100.0
  pinCount *= 1

  housing = pattern.housing
  settings = pattern.settings

  #console.log housing
