module.exports = (symbol, element) ->
  element.refDes = '#FLG'
  element.power = true
  element.description = 'Power Flag'
  settings = symbol.settings

  schematic = element.schematic
  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  width = 5 * settings.factor
  height = 5 * settings.factor

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
      out: true
      invisible: true
    .lineWidth settings.lineWidth.thick
    .line 0, 0, 0, -height/3
    .line 0, -height/3, width/2, -height/3*2
    .line width/2, -height/3*2, 0, -height
    .line 0, -height, -width/2, -height/3*2
    .line -width/2, -height/3*2, 0, -height/3
