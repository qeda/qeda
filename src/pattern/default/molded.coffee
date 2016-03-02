twoPin = require './common/two-pin'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.molded = true
  twoPin pattern, element
