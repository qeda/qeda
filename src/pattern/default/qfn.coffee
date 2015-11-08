sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
quad = require './common/quad'

module.exports = (pattern, housing) ->
  pattern.name ?= sprintf "%sQFN%dP%dX%dX%d-%d",
    if housing.pullBack? then 'P' else '',
    [housing.pitch*100
    housing.bodyWidth.nom*100
    housing.bodyLength.nom*100
    housing.height*100
    housing.leadCount]
    .map((a) => Math.round a)...

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.qfn pattern, housing
  padParams.defaultShape = 'oval'
  padParams.pitch = housing.pitch
  padParams.count1 = housing.leadCount1
  padParams.count2 = housing.leadCount2

  pattern.setLayer 'top'
  quad pattern, padParams
