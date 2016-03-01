twopin = require './common/twopin'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.chip = true
  twopin pattern, element
