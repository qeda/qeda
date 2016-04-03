sot = require('./sot')

module.exports = (pattern, element) ->
  housing = element.housing
  housing.flatlead = true
  housing.polarized = true
  sot pattern, element
