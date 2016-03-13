sprintf = require('sprintf-js').sprintf

assembly = require './assembly'
calculator = require './calculator'
copper = require './copper'
courtyard = require './courtyard'
silkscreen = require './silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  leadCount = housing.leadCount
  hasTab = housing.tabWidth? and housing.tabLength?
  if hasTab then ++leadCount

  if housing.cfp
    abbr = 'CFP'
    option = 'sop'
  else if housing.flatlead
    abbr = 'SOPFL'
    option = 'flatlead'
  else if housing.soic
    abbr = 'SOIC'
    option = 'sop'
  else if housing.soj
    abbr = 'SOJ'
    option = 'soj'
  else if housing.sol
    abbr = 'SOL'
    option = 'sol'
  else if housing.son
    abbr = 'SON'
    option = 'son'
  else
    abbr = 'SOP'
    option = 'sop'

  pattern.name ?= sprintf "%s%dP%dX%d-%d%s",
    abbr,
    [housing.pitch*100
    housing.leadSpan.nom*100
    housing.height.max*100
    leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.dual pattern, housing, option
  padParams.order = 'round'
  padParams.pad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width
    height: padParams.height
    layer: ['topCopper', 'topMask', 'topPaste']

  copper.dual pattern, element, padParams
  silkscreen.dual pattern, housing
  assembly.polarized pattern, housing
  courtyard.dual pattern, housing, padParams.courtyard

  copper.tab pattern, element
