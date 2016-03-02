twoPin = require './common/two-pin'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.crystal = true
  twoPin pattern, element
