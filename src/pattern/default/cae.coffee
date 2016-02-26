sprintf = require('sprintf-js').sprintf
chip = require './chip'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
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
  pattern.name ?= sprintf "CAPAE%dX%d%s",
    [housing.bodyWidth.nom*100
    height*100]
    .map((v) => Math.round v)...,
    settings.densityLevel

  chip pattern, element
