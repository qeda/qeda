gridArray = require './common/grid-array'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.cga = true
  gridArray pattern, element
