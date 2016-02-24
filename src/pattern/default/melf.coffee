chip = require './chip'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.melf = true
  chip pattern, element
