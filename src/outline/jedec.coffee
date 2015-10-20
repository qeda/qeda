JEDEC =
  'MS-012AA':
    bodyLength: [4.80, 5.00]
    bodyWidth: [3.80, 4.00]
    height: [1.75]
    leadHeight: [0.19, 1.25]
    leadLength: [0.40, 1.27]
    leadSpan: [5.80, 6.20]
    leadWidth: [0.31, 0.51]
    pitch: 1.27

module.exports = (housing, outline) ->
  if JEDEC[outline]?
    for key, value of JEDEC[outline]
      housing[key] = value
