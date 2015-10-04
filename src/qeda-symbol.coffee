#
# Class for schematics symbol
#
class QedaSymbol
  constructor: (@element) ->
    @pins = []

  pinDef: (pinNum) ->
    @element.pinDef pinNum

  addPin: (pin) ->
    newPin = {}
    for own prop of pin
      newPin[prop] = pin
    @pins.push newPin

module.exports = QedaSymbol
