twoPin = require './common/two-pin'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.sodfl = true
  twoPin pattern, element
