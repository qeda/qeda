#
# Class for schematics symbol
#
class QedaSymbol
  constructor: (@element) ->
    @pins = []
    @attributes = []

  
  addPin: (pin) ->
    newPin = {}
    for own prop of pin
      newPin[prop] = pin
    @pins.push newPin

  attribute: (key) ->
    @attributes[key]

  pinDef: (pinNum) ->
    @element.pinDef pinNum

  setAttribute: (key, value) ->
    @attributes[key] = value

module.exports = QedaSymbol
