dual = require './common/dual'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.pitch = 1.27
  housing.cfp = true
  dual pattern, element
