chip = require './chip'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.crystal = true
  chip pattern, element
