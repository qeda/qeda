twoPin = require './common/two-pin'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.sod = true
  twoPin pattern, element
