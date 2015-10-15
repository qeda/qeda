#
# Class for schematics symbol
#
class QedaSymbol
  constructor: (@element) ->
    @pins = []
    @attributes = []

  #
  # Add pin record
  #
  addPin: (pin) ->
    newPin = {}
    for own prop of pin
      newPin[prop] = pin
    @pins.push newPin

  #
  # Get attribute
  #
  attribute: (key) ->
    @attributes[key]

  #
  # Convert inner units to physical (mm, mil etc.)
  #
  calculate: (gridSize) ->
    @_calculated ?= false
    if @_calculated then return
    for pin in @pins
      if pin.x? then pin.x *= gridSize
      if pin.y? then pin.y *= gridSize
    for _, attr of @attributes
      if attr.x? then attr.x *= gridSize
      if attr.y? then attr.y *= gridSize
    @_calculated = true

  #
  # Get pin definition
  #
  pinDef: (pinNum) ->
    @element.pinDef pinNum

  #
  # Assign attribute to new value
  #
  setAttribute: (key, value) ->
    @attributes[key] = value

module.exports = QedaSymbol
