sprintf = require('sprintf-js').sprintf

assembly = require './common/assembly'
calculator = require './common/calculator'
copper = require './common/copper'
courtyard = require './common/courtyard'
silkscreen = require './common/silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  housing.polarized = true
  housing.flatlead = true
  housing.leadCount ?= 5
  settings = pattern.settings
  pattern.name ?= sprintf "SOTFL%dP%dX%d-%d%s",
    [housing.pitch*100
    housing.leadSpan.nom*100
    housing.height.max*100
    housing.leadCount]
    .map((v) => Math.round v)...,
    settings.densityLevel

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.sot pattern, housing

  pad1 =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width1
    height: padParams.height1
    layer: ['topCopper', 'topMask', 'topPaste']
  pad2 =
    type: 'smd'
    shape: 'rectangle'
    x: 0
    y: 0
    width: padParams.width2 + padParams.distance
    height: padParams.height2
    layer: ['topCopper', 'topMask', 'topPaste']


  pad1.x = -padParams.distance / 2
  pad1.y = -housing.pitch
  pattern.pad 1, pad1

  pattern.pad 2, pad2

  pad1.y = housing.pitch
  pattern.pad 3, pad1

  pad1.x = padParams.distance / 2
  pattern.pad 4, pad1

  pad1.y = -housing.pitch
  pattern.pad 5, pad1

  # Other layers
  copper.mask pattern
  silkscreen.dual pattern, housing
  assembly.polarized pattern, housing
  courtyard.dual pattern, housing, padParams.courtyard
