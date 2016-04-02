resistor = require '../default/resistor'

module.exports = (symbol, element) ->
  [width, height] = resistor symbol, element
  gap = 1.2
  dx = width / 8
  dy = height/2 - gap
  if element.keywords?
    keywords = element.keywords.toLowerCase().replace(/\s+/g, '').split(',')
    if keywords.indexOf('1/10w') isnt -1
      space = width / 4
      for i in [-1..1]
        symbol.line -dx + i*space, -dy, dx + i*space, dy
    else if keywords.indexOf('1/8w') isnt -1
      space = width / 4
      for i in [0..1]
        symbol.line -dx + (i - 0.5)*space, -dy, dx + (i - 0.5)*space, dy
    else if keywords.indexOf('1/4w') isnt -1
      symbol.line -dx, -dy, dx, dy
    else if keywords.indexOf('1/2w') isnt -1
      symbol.line -dx, 0, dx, 0
    else if keywords.indexOf('1w') isnt -1
      symbol.line 0, -dy, 0, dy
    else if keywords.indexOf('2w') isnt -1
      space = width / 6
      for i in [0..1]
        symbol.line (i - 0.5)*space, -dy, (i - 0.5)*space, dy
    else if keywords.indexOf('3w') isnt -1
      space = width / 6
      for i in [-1..1]
        symbol.line i*space, -dy, i*space, dy
    else if keywords.indexOf('5w') isnt -1
        symbol
          .line -dx, -dy, 0, dy
          .line dx, -dy, 0, dy
