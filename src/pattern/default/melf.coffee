twopin = require './common/twopin'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.melf = true
  twopin pattern, element
