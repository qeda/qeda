sprintf = require('sprintf-js').sprintf

assembly = require './common/assembly'
calculator = require './common/calculator'
copper = require './common/copper'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.polarized = true
  housing.leadWidth ?= housing.leadDiameter
  housing.leadHeight ?= housing.leadDiameter

  pattern.name ?= sprintf "%sDIP%s%dW%dP%dL%dH%dQ%d",
    if housing.ceramic? then 'C' else '',
    if housing.socket? then 'S' else '',
    [housing.leadSpan.nom*100
    housing.leadWidth.nom*100
    housing.pitch*100
    housing.bodyLength.nom*100
    housing.height.nom*100
    housing.leadCount]
    .map((v) => Math.round v)...,

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.throughHole pattern, housing

  padParams.distance = housing.leadSpan.nom
  padParams.pitch = housing.pitch
  padParams.count = housing.leadCount
  padParams.order = 'round'
  padParams.pad =
    type: 'through-hole'
    shape: 'circle'
    drill: padParams.drill
    width: padParams.width
    height: padParams.height
    layer: ['topCopper', 'topMask', 'topPaste', 'bottomCopper', 'bottomMask', 'bottomPaste']

  copper.dual pattern, element, padParams
  firstPad = pattern.pads[Object.keys(pattern.pads)[0]]
  firstPad.shape = 'rectangle'

  silkscreen.dual pattern, housing
  assembly.polarized pattern, housing
  courtyard.dual pattern, housing, 0.5
