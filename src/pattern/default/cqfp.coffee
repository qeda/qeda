qfp = require './qfp'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.cqfp = true
  qfp pattern, element
