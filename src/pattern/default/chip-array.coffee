sprintf = require('sprintf-js').sprintf

assembly = require './common/assembly'
calculator = require './common/calculator'
copper = require './common/copper'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'

abbrs =
  CAP: 'capacitor'
  IND: 'inductor'
  RES: 'resistor'

getAbbr = (element) ->
  abbr = 'U'
  unless element.keywords? then return name
  keywords = element.keywords.toLowerCase().replace(/\s+/g, '').split(',')
  for k, v of abbrs
    if keywords.indexOf(v) isnt -1
      abbr = k
      break
  abbr

module.exports = (pattern, element) ->
  settings = pattern.settings
  housing = element.housing
  housing.leadSpan ?= housing.bodyWidth

  abbr = getAbbr element
  abbr += 'CA'
  if housing.concave
    abbr += 'V'
  else if housing['convex-e']
    abbr += 'XE'
  else if housing['convex-s']
    abbr += 'XS'
  else if housing.flat
    abbr += 'F'
  pattern.name ?= sprintf "%s%dP%dX%dX%d-%d%s",
    abbr,
    [housing.pitch*100
    housing.bodyLength.nom*100
    housing.bodyWidth.nom*100
    housing.height.max*100
    housing.leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  padParams = calculator.chipArray pattern, housing
  padParams.order = 'round'
  padParams.pad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width
    height: padParams.height
    layer: ['topCopper', 'topMask', 'topPaste']

  copper.dual pattern, element, padParams
  silkscreen.dual pattern, housing
  assembly.body pattern, housing
  courtyard.dual pattern, housing, padParams.courtyard
