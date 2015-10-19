JEDEC =
  'MS-012AA':
    A: [3.80, 4.00]
    B: [4.80, 5.00]
    L: [5.80, 6.20]
    T: [0.40, 1.27]
    W: [0.31, 0.51]

module.exports = (housing, outline) ->
  if JEDEC[outline]?
    for key, value of JEDEC[outline]
      housing[key] = value
