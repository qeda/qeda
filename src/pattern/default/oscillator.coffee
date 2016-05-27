sprintf = require('sprintf-js').sprintf

assembly = require './common/assembly'
calculator = require './common/calculator'
copper = require './common/copper'
courtyard = require './common/courtyard'
chipArray = require './chip-array'
silkscreen = require './common/silkscreen'

module.exports = (pattern, element) ->
  settings = pattern.settings
  housing = element.housing
  housing.polarized = true

  abbr = 'OSC'

  if housing['corner-concave']
    abbr += 'CC'
  else if housing.dfn
    abbr += 'DFN'
  else if housing['side-concave']
    abbr += 'SC'
  else if housing['side-flat']
    abbr += 'SF'

  if housing['corner-concave']
    size = sprintf "%02dX%02dX%d",
      [housing.bodyLength.nom*100
      housing.bodyWidth.nom*100
      housing.height.max*100]
      .map((v) => Math.round v)...
  else
    size = sprintf "%dP%02dX%02dX%d-%d",
      [housing.pitch*100
      housing.bodyLength.nom*100
      housing.bodyWidth.nom*100
      height*100
      housing.leadCount]
      .map((v) => Math.round v)...

  pattern.name ?= sprintf "%s%s%s",
    abbr,
    size,
    settings.densityLevel

  if housing['corner-concave']
    # Calculate pad dimensions according to IPC-7351
    padParams = calculator.cornerConcave pattern, housing
    padParams.distance = padParams.distance1
    housing.pitch = padParams.distance2
    housing.leadCount = 4
    padParams.pad =
      type: 'smd'
      shape: 'rectangle'
      width: padParams.width
      height: padParams.height
      layer: ['topCopper', 'topMask', 'topPaste']

    copper.dual pattern, element, padParams
    silkscreen.dual pattern, housing
    assembly.polarized pattern, housing
    courtyard.boundary pattern, housing, padParams.courtyard
  else if housing.dfn
    # TODO: Add DFN
  else # side-concave, side-flat
    if housing['side-concave'] then housing.concave = true
    if housing['side-flat'] then housing.flat = true
    chipArray pattern, element
