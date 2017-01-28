module.exports = (symbol, element) ->
  element.refDes = '#PWR'
  element.power = true
  element.description = 'Power Symbol'
  settings = symbol.settings

  schematic = element.schematic
  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  width = 2.5 * settings.factor
  height = 5 * settings.factor
  arrowHeight = width

  symbol
    .attribute 'refDes',
      x: 0
      y: settings.space.attribute
      halign: 'center'
      valign: 'top'
      visible: false
    .attribute 'name',
      x: 0
      y: -height - settings.space.attribute
      halign: 'center'
      valign: 'bottom'
    .pin
      number: 1
      name: element.name
      x: 0
      y: 0
      length: 0
      orientation: 'up'
      power: true
      invisible: true
    .line 0, 0, 0, -height
    .lineWidth settings.lineWidth.thick
    .line 0, -height, width/2, -height + arrowHeight
    .line 0, -height, -width/2, -height + arrowHeight
