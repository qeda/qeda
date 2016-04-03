dual = require './common/dual'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.soj = true
  housing.polarized = true
  dual pattern, element
