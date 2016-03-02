twoPin = require './common/two-pin'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.melf = true
  twoPin pattern, element
