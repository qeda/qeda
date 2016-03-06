gridArray = require './common/grid-array'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.lga = true
  gridArray pattern, element
