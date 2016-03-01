sprintf = require('sprintf-js').sprintf
chip = require './chip'

module.exports = (pattern, element) ->
  housing = element.housing
  height = housing.height.max ? housing.height
  unless housing.leadSpan?
    tol = Math.sqrt(housing.leadLength.tol*housing.leadLength.tol + housing.leadSpace.tol*housing.leadSpace.tol)
    nom = 2*housing.leadLength.nom + housing.leadSpace.nom
    housing.leadSpan ?=
      min: nom - tol/2
      nom: nom
      max: nom + tol/2
      tol: tol
  housing.cae = true
  chip pattern, element
