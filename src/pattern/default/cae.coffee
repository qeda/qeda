twoPin = require './common/two-pin'

module.exports = (pattern, element) ->
  housing = element.housing
  if housing.leadSpan?
    nom = (housing.leadSpan.nom - housing.leadSpace.nom) / 2
    min = (housing.leadSpan.min - housing.leadSpace.max) / 2
    max = (housing.leadSpan.max - housing.leadSpace.min) / 2
    housing.leadLength ?=
      min: min
      nom: nom
      max: max
      tol: max - min
  else
    tol = Math.sqrt(housing.leadLength.tol*housing.leadLength.tol + housing.leadSpace.tol*housing.leadSpace.tol)
    nom = 2*housing.leadLength.nom + housing.leadSpace.nom
    housing.leadSpan ?=
      min: nom - tol/2
      nom: nom
      max: nom + tol/2
      tol: tol
  housing.cae = true
  twoPin pattern, element
