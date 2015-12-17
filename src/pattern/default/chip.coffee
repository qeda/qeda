sprintf = require('sprintf-js').sprintf
calculator = require './common/calculator'
dual = require './common/dual'

abbrs =
  CAPC: ['capacitor']
  RESC: ['resistor']
  RESDFN: ['resistor', 'no-lead']
  RESMELF: ['resistor', 'melf']
  RESM: ['resistor', 'molded']
  RESSC: ['resistor', 'concave']

getName = (element) ->
  name = 'U'
  unless element.keywords? then return name
  keywords = element.keywords.replace(/\s+/g, '').split(',')
  abbrWeight = 0
  for abbr, classes of abbrs
    weight = keywords.filter((a) => classes.indexOf(a) isnt -1).length
    if weight > abbrWeight
      abbrWeight = weight
      name = abbr
  name

module.exports = (pattern, element) ->
  housing = element.housing
  height = housing.height.max ? housing.height
  pattern.name ?= sprintf "%s%dX%dX%d",
    getName(element),
    [housing.length.nom*100
    housing.width.nom*100
    height*100]
    .map((a) => Math.round a)...

  settings = pattern.settings

  # Calculate pad dimensions according to IPC-7351
  housing.bodyWidth ?= housing.width
  housing.bodyLength ?= housing.length
  housing.leadWidth ?= housing.bodyWidth
  housing.leadSpan ?= housing.bodyLength
  padParams = calculator.sop pattern, housing

  console.log padParams
