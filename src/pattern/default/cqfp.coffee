quad = require './common/quad'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.cqfp = true
  quad pattern, element
