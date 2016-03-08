quad = require './common/quad'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.qfn = true
  quad pattern, element
