chip = require './chip'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.molded = true
  chip pattern, element
