dual = require './common/dual'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.son = true
  dual pattern, element
