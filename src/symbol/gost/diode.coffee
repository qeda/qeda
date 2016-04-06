Icons = require './common/icons'
diode = require '../default/diode'

module.exports = (symbol, element) ->
  diode symbol, element, Icons
  element.refDes = 'VD'
