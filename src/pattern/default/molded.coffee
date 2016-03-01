twopin = require './common/twopin'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.molded = true
  twopin pattern, element
