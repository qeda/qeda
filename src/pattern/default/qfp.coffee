quad = require './common/quad'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.qfp = true
  quad pattern, element
