twopin = require './common/twopin'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.sodfl = true
  twopin pattern, element
