gridArray = require './common/grid-array'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.bga = true
  gridArray pattern, element
