twopin = require './common/twopin'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.crystal = true
  twopin pattern, element
