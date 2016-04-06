Icons = require './common/icons'
twinDiode = require '../default/twin-diode'

module.exports = (symbol, element) ->
  twinDiode symbol, element, Icons
  element.refDes = 'VD'
