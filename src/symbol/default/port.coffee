portSymbol = (symbol, element) ->
  settings = symbol.settings
  schematic = element.schematic

  size = 3 * settings.factor
  width = 3 * size
  height = 2 * size
  symbol
    .attribute 'refDes',
      x: if schematic.input then 0 else width
      y: 0 - settings.space.attribute
      halign: if schematic.input then 'left' else 'right'
      valign: 'bottom'
    .pin
      number: 1
      name: if schematic.input then 'Y' else 'A'
      x: if schematic.input then width else 0
      y: height/2
      length: 0
      orientation: if schematic.input then 'left' else 'right'
    .lineWidth settings.lineWidth.thick
  if schematic.input
    element.description = 'Input Port Symbol'
    element.aliases ?= []
    element.aliases.push('$_inputExt_')
    symbol.polyline(0, 0,
                    0, height,
                    width/2, height,
                    width, height/2,
                    width/2, 0,
                    0, 0)
  else if schematic.output
    element.description = 'Output Port Symbol'
    element.aliases ?= []
    element.aliases.push('$_outputExt_')
    symbol.polyline(width, 0,
                    width, height,
                    width/2, height,
                    0, height/2,
                    width/2, 0,
                    width, 0)

module.exports = (symbol, element) ->
  element.refDes = '#PORT'

  schematic = element.schematic
  schematic.showPinNames ?= false
  schematic.showPinNumbers ?= false

  portSymbol symbol, element
