module.exports = (element, pitch, span, height, pinCount) ->
  pitch /= 100.0
  span /= 100.0
  height /= 100.0
  pinCount *= 1

  element.setLayer 'topSilk'
  element.rect 0, 0, 10, 10
  element.setLayer 'top'
