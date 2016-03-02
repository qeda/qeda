twoPin = require './common/two-pin'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.chip = true
  twoPin pattern, element
