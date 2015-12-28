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
  pattern.name ?= sprintf "%s%02d%02dX%d",
    getName(element),
    [housing.bodyLength.nom*10
    housing.bodyWidth.nom*10
    height*100]
    .map((a) => Math.round a)...

  settings = pattern.settings

  # Calculate pad dimensions according to IPC-7351
  padParams = calculator.chip pattern, housing

  pad =
    type: 'smd'
    shape: 'rectangle'
    width: padParams.width
    height: padParams.height
    layer: ['topCopper', 'topMask', 'topPaste']
    x: -padParams.distance/2
    y: 0

  # Copper
  pattern.pad 1, pad
  pad.x = -pad.x
  pattern.pad 2, pad

  # Silkscreen
  lineWidth = settings.lineWidth.silkscreen
  bodyWidth = housing.bodyWidth.nom
  bodyLength = housing.bodyLength.nom
  x = bodyLength/2
  y = padParams.height/2 + lineWidth/2 + settings.clearance.padToSilk
  pattern
    .layer 'topSilkscreen'
    .lineWidth lineWidth
    .attribute 'refDes',
      x: 0
      y: 0
      halign: 'center'
      valign: 'center'
    .line -x, -y, x, -y
    .line -x, y, x, y

  # Assembly
  x = bodyLength/2
  y = bodyWidth/2
  d = 1
  pattern
    .layer 'topAssembly'
    .lineWidth settings.lineWidth.assembly
    .attribute 'value',
      text: pattern.name
      x: 0
      y: y + settings.fontSize.value/2 + 0.5
      halign: 'center'
      valign: 'center'
      visible: false
    .rectangle -x, -y, x, y

  # Courtyard
  courtyard = padParams.courtyard
  x = (padParams.width + padParams.distance)/2 + courtyard
  y = padParams.height/2 + courtyard
  pattern
    .layer 'topCourtyard'
    .lineWidth settings.lineWidth.courtyard
    # Centroid origin marking
    .circle 0, 0, 0.5
    .line -0.7, 0, 0.7, 0
    .line 0, -0.7, 0, 0.7
    # Contour courtyard
    .rectangle -x, -y, x, y
