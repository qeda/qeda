assert = require 'assert'
custom = require '../src/pattern/default/custom'
log = require '../src/qeda-log'

makePattern = ->
  pattern =
    settings:
      decimals: 3
      densityLevel: 'N'
      minimum:
        maskWidth: null
      lineWidth:
        assembly: 0.1
        courtyard: 0.05
        silkscreen: 0.12
      fontSize:
        default: 1
    shapes: []
    pads: []
    cx: 0
    cy: 0
    center: (x, y) ->
      @cx = x
      @cy = y
      this
    parsePosition: (value) ->
      values = value.toString().replace(/\s+/g, '').split(',').map Number
      ({x: values[i], y: values[i + 1]} for i in [0...values.length] by 2)
    parseArray: (value) ->
      return [0] unless value?
      value.toString().replace(/\s+/g, '').split(',').map Number
    pad: (name, pad) ->
      copy = Object.assign {}, pad,
        name: name
        x: @cx + pad.x
        y: @cy + pad.y
      @pads.push copy
      @_addShape 'pad', copy
      this
    _addShape: (kind, shape) ->
      result = Object.assign {kind: kind}, shape
      @shapes.push result
      result

  for method in ['attribute', 'circle', 'fill', 'layer', 'line', 'lineWidth', 'rectangle', 'silkRectangle']
    pattern[method] = -> this
  pattern

makeElement = (overrides = {}) ->
  housing = Object.assign
    pattern: 'custom'
    bodyWidth: {nom: 3}
    bodyLength: {nom: 3}
    holeDiameter: 1
    padDiameter: 2
    padPosition: '0, 0'
    pinInPasteSplit: true
  , overrides
  name: 'split-paste-test'
  group: 'test'
  housing: housing
  pins: {'1': {}}
  parsePinNumbers: (value) -> [value.toString()]

pasteShapes = (pattern) ->
  pattern.shapes.filter (shape) -> shape.kind is 'poly' and shape.layer?[0] is 'topPaste'

pattern = makePattern()
custom pattern, makeElement()
assert.strictEqual pasteShapes(pattern).length, 2

pattern = makePattern()
custom pattern, makeElement
  pinInPasteSplitSegments: 4
  pinInPasteSplitGap: 0.2
  pinInPasteSplitInnerDiameterOffset: 0.1
  pinInPasteSplitOuterDiameterOffset: 0.2
shapes = pasteShapes pattern
assert.strictEqual shapes.length, 4

outerPointCount = (shapes[0].points.length - 2) / 4
firstEnd = shapes[0].points[(outerPointCount - 1) * 2..(outerPointCount - 1) * 2 + 1]
secondStart = shapes[1].points[0..1]
measuredGap = Math.sqrt Math.pow(firstEnd[0] - secondStart[0], 2) + Math.pow(firstEnd[1] - secondStart[1], 2)
assert Math.abs(measuredGap - 0.2) < 1e-9

radii = shapes[0].points.reduce ((result, value, index, points) ->
  return result if index % 2
  radius = Math.sqrt(value * value + points[index + 1] * points[index + 1])
  result.push radius
  result
), []
assert Math.abs(Math.max(radii...) - 1.2) < 1e-9
assert Math.abs(Math.min(radii...) - 0.4) < 1e-9

originalError = log.error
log.error = (message) -> throw new Error message
assert.throws ->
  custom makePattern(), makeElement
    pinInPasteSplitInnerDiameterOffset: -0.3
    pinInPasteSplitOuterDiameterOffset: -0.3
, /offsets collapse or invert/
log.error = originalError
