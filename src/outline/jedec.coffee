JEDEC =
  'MS':
    '012': # MS-012
      bodyWidth: [3.80, 4.00]
      leadLength: [0.40, 1.27]
      leadSpan: [5.80, 6.20]
      leadWidth: [0.31, 0.51]
      pitch: 1.27
      'AA': # MS-012AA
        bodyLength: [4.80, 5.00]
        height: [1.75]
        leadCount: 8
    '026': # MS-026
      leadLength: [0.45, 0.75]
      'BFB': # MS-026BFB
        bodyLength: [19.80, 20.20]
        bodyWidth: [19.80, 20.20]
        height: [1.60]
        leadCount: 144
        leadCount1: 36
        leadCount2: 36
        leadSpan1: [21.80, 22.20]
        leadSpan2: [21.80, 22.20]
        leadWidth: [0.17, 0.27]
        pitch: 0.5

module.exports = (housing, outline) ->
  cap = /([A-Z]+)-(\d+)([A-Z]+)/.exec outline
  jedec = JEDEC
  for key in cap[1..]
    jedec = jedec[key]
    unless jedec? then break
    for subkey, subvalue of jedec
      if (typeof subvalue is 'number') or Array.isArray subvalue
        housing[subkey] = subvalue
