dual = require './common/dual'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.sol = true
  dual pattern, element
