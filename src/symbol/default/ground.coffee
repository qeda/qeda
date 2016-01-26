module.exports = (symbol, element) ->
  element.refDes = '#PWR'
  element.power = true
  settings = symbol.settings

  width = 5
  height = 2.5

  symbol
    .attribute 'refDes',
      x: 0
      y: -1
      halign: 'center'
      valign: 'bottom'
      visible: false
    .attribute 'name',
      x: 0
      y: height + 1.5
      halign: 'center'
      valign: 'top'
    .pin
      number: 1
      name: element.name
      x: 0
      y: 0
      length: 0
      orientation: 'down'
      ground: true
      invisible: true
    .line 0, 0, 0, height
    .lineWidth settings.lineWidth.thick
    .line -width/2, height, width/2, height
