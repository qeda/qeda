sot = require('./sot')

module.exports = (pattern, element) ->
  housing = element.housing
  housing.flatlead = true
  sot pattern, element
