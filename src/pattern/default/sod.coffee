twopin = require './common/twopin'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.sod = true
  twopin pattern, element
