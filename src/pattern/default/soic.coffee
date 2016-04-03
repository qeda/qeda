dual = require './common/dual'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.pitch ?= 1.27
  housing.soic = true
  housing.polarized = true
  dual pattern, element
