enclosure = require './common/enclosure'
icons = require './common/icons'

module.exports = (symbol, element) ->
  schematic = element.schematic
  element.refDes = schematic.refDes || 'U'
  schematic.showPinNames ?= true
  schematic.showPinNumbers ?= true
  icon = undefined

  if schematic.icon?
    for key in Object.keys icons
      if String(schematic.icon).toLowerCase() is key.toLowerCase()
        icon = new icons[key](symbol, element)

  enclosure symbol, element, icon
