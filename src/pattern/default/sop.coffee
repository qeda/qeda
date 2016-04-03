dual = require './common/dual'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.sop = true
  housing.polarized = true
  dual pattern, element
