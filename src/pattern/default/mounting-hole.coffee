calculator = require './common/calculator'
copper = require './common/copper'
courtyard = require './common/courtyard'
addPinInPasteSplit = require './common/pin-in-paste-split'
silkscreen = require './common/silkscreen'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  pattern.name ?= element.name.toUpperCase()

  pad =
    x: 0
    y: 0
    hole: housing.holeDiameter
    shape: if housing.padDiameter? then 'circle' else 'rectangle'

  if housing.padDiameter? or housing.padWidth? or housing.padHeight?
    housing.padWidth ?= housing.padDiameter
    housing.padHeight ?= housing.padDiameter
    pad.type = 'through-hole'
    pad.layer = ['topCopper', 'topMask', 'intCopper', 'bottomCopper', 'bottomMask']
    pad.width = housing.padDiameter ? housing.padWidth
    pad.height = housing.padDiameter ? housing.padHeight
  else
    pad.type = 'mounting-hole'
    pad.layer = ['topCopper', 'topMask', 'intCopper', 'bottomCopper', 'bottomMask']
    pad.width = housing.holeDiameter
    pad.height = housing.holeDiameter
    pad.shape = 'circle'
  if housing.toppaste? and not housing.pinInPasteSplit
    pad.layer.push 'topPaste'
  if housing.bottompaste? and not housing.pinInPasteSplit
    pad.layer.push 'bottomPaste'

  pattern.pad 1, pad

  if housing.pinInPasteSplit
    splitPasteOptions =
      segments: housing.pinInPasteSplitSegments
      gap: housing.pinInPasteSplitGap
      innerDiameterOffset: housing.pinInPasteSplitInnerDiameterOffset
      outerDiameterOffset: housing.pinInPasteSplitOuterDiameterOffset
    pasteLayers = []
    pasteLayers.push 'topPaste' if housing.toppaste?
    pasteLayers.push 'bottomPaste' if housing.bottompaste?
    pasteLayers.push 'topPaste' unless pasteLayers.length
    for layer in pasteLayers
      splitPasteOptions.layer = [layer]
      addPinInPasteSplit pattern, pad, pad.hole, pad.hole, splitPasteOptions

  copper.mask pattern

  if housing.viaDiameter?
    d = housing.padDiameter ? Math.min(housing.padWidth, housing.padHeight)
    viaPad =
      type: 'through-hole'
      shape: 'circle'
      hole: housing.viaDiameter
      width: housing.viaDiameter + settings.minimum.ringWidth
      height: housing.viaDiameter + settings.minimum.ringWidth
      layer: ['topCopper', 'bottomCopper']
    count = housing.viaCount ? 8
    r = housing.holeDiameter/2 + (d - housing.holeDiameter)/4
    for i in [0..(count-1)]
      angle = i*2*Math.PI/count
      viaPad.x = r*Math.cos(angle)
      viaPad.y = r*Math.sin(angle)
      pattern.pad 1, viaPad

  housing.keepout ?= { M: 0.5, N: 0.25, L: 0.12 }[settings.densityLevel]

  housing.bodyWidth ?= housing.bodyDiameter

  courtyardsize =
    radius: (housing.bodyWidth?.max ? pad.width) / 2
    halfwidth: (housing.bodyWidth?.max ? pad.width) / 2
    halfheight: (housing.bodyHeight?.max ? pad.height) / 2
  courtyard.preamble pattern, housing
  if pad.shape is 'circle'
    pattern.circle 0, 0, courtyardsize.radius + housing.keepout
  else
    pattern.rectangle -courtyardsize.halfwidth - housing.keepout, -courtyardsize.halfheight - housing.keepout, courtyardsize.halfwidth/2 + housing.keepout, courtyardsize.halfheight + housing.keepout

  # Assembly layer
  pattern
    .layer 'topAssembly'
    .lineWidth settings.lineWidth.assembly
    .attribute 'refDes',
      x: 0
      y: 0
      halign: 'center'
      valign: 'center'
    .attribute 'value',
      text: pattern.name
      x: 0
      y: 0
      halign: 'center'
      valign: 'center'
      visible: false
