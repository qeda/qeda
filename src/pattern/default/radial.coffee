twoPin = require './common/two-pin'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.radial = true
  twoPin pattern, element
