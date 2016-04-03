dual = require './common/dual'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.sol = true
  housing.polarized = true
  dual pattern, element
