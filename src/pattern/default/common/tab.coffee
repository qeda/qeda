module.exports = (pattern, housing) ->
  hasTab = housing.tabWidth? and housing.tabLength?
  if hasTab
    housing.tabOffset ?= '0, 0'
    [x, y] = housing.tabOffset.replace(/\s+/g, '').split(',').map((v) => parseFloat(v))

    tabNumber = (housing.leadCount ? 2*(housing.rowCount + housing.columnCount)) + 1
    tabPad =
      type: 'smd'
      shape: 'rectangle'
      width: housing.tabWidth.nom ? housing.tabWidth
      height: housing.tabLength.nom ? housing.tabLength
      layer: ['topCopper', 'topMask', 'topPaste']
      x: x
      y: y
    pattern.pad tabNumber, tabPad
