groundSymbol = (symbol, element, icon = 'signal') ->
  settings = symbol.settings
  schematic = element.schematic

  width = 5 * settings.factor
  height = 5 * settings.factor

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
    .line 0, 0, 0, (if schematic.signal or schematic.earth or schematic.chassis then height/2 else height)
    .lineWidth settings.lineWidth.thick
  if schematic.signal
    element.description = 'Signal Ground Symbol'
    symbol.poly -width/2, height/2, width/2, height/2, 0, height, -width/2, height/2, settings.fill
  else if schematic.earth
    element.description = 'Earth Ground Symbol'
    d = width/5
    symbol
      .line -width/2, height/2, width/2, height/2
      .line -width/2 + d, 3*height/4, width/2 - d, 3*height/4
      .line -width/2 + 2*d, height, width/2 - 2*d, height
  else if schematic.chassis
    element.description = 'Chassis Ground Symbol'
    d = width/4
    symbol
      .line -width/2, height/2, width/2, height/2
      .line -width/2, height/2, -width/2 - d, height
      .line 0, height/2, -d, height
      .line width/2, height/2, width/2 - d, height
  else
    element.description = 'Ground Symbol'
    symbol.line -width/2, height, width/2, height

module.exports = (symbol, element) ->
  element.refDes = '#PWR'
  element.power = true

  schematic = element.schematic
  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  groundSymbol symbol, element
