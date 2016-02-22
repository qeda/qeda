sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
dual = require './common/dual'
tab = require './common/tab'

module.exports = (pattern, element) ->
  housing = element.housing
  height = housing.height.max ? housing.height
  leadCount = housing.leadCount
  hasTab = housing.tabWidth? and housing.tabLength?
  if hasTab then ++leadCount
  pattern.name ?= sprintf "SON%dP%dX%d-%d",
    [housing.pitch*100
    housing.leadSpan.nom*100
    height*100
    leadCount]
    .map((v) => Math.round v)...
