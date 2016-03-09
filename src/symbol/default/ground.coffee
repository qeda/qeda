module.exports = (symbol, element) ->
  element.refDes = '#PWR'
  element.power = true
  settings = symbol.settings

  width = 5
  height = 5

  symbol
    .attribute 'refDes',
      x: 0
      y: -settings.space.attribute
      halign: 'center'
      valign: 'bottom'
      visible: false
    .attribute 'name',
      x: 0
      y: height + settings.space.attribute
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
    .line 0, 0, 0, height/2
    .lineWidth settings.lineWidth.thick
    .polyline -width/2, height/2, width/2, height/2, 0, height, -width/2, height/2
