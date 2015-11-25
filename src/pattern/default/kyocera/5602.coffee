dual = require '../common/dual'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  pattern.name ?= 'KYOCERA_' + element.name

  padParams =
    pitch: 0.4
    count: Object.keys(element.pins).length
    order: 'rows'
    pad:
      type: 'smd'
      shape: 'rectangle'
      height: 0.23
      mask: 0.01
      layer: ['topCopper', 'topMask', 'topPaste']

  switch housing.type

    when 'plug'
      padParams.pad.width = 0.7
      padParams.distance = 3.56
      bodyWidth = 2.06
      bodyLength = padParams.pitch * padParams.count/2 + 1.1

      dual pattern, padParams
      if housing.boss
        bossPad =
          type: 'mount'
          name: 'MH'
          drill: 0.65
          x: -0.6
          y: -(padParams.pitch * padParams.count/2 + 0.5) / 2
          layer: ['topCopper', 'topMask', 'intCopper', 'bottomCopper', 'bottomMask']
        pattern.pad 'MH1', bossPad
        bossPad.x = -bossPad.x
        bossPad.y = -bossPad.y
        pattern.pad 'MH2', bossPad

    when 'receptacle'
      padParams.pad.width = 1
      padParams.distance = 4.5
      padParams.mirror = true
      bodyWidth = 4
      bodyLength = padParams.pitch * padParams.count/2 + 2.1

      dual pattern, padParams

  lineWidth = settings.lineWidth.silkscreen
  # Boundary
  boundWidth = 4
  boundLength = padParams.pitch * padParams.count/2 + 2.1
  padHeight = padParams.pad.height
  x = boundWidth/2
  y1 = boundLength/2
  y2 = padParams.pitch*(padParams.count/4 - 0.5) + padHeight/2 + lineWidth/2 + settings.clearance.padToSilk
  fontSize = settings.fontSize.refDes
  pattern
    .layer 'topSilkscreen'
    .lineWidth lineWidth
    .attribute 'refDes',
      x: 0
      y: -boundLength/2 - fontSize/2 - 2*lineWidth
      halign: 'center'
      valign: 'center'
    .line -x,  y1,  x,  y1
    .line  x,  y1,  x,  y2
    .line -x,  y1, -x,  y2
    .line -x, -y1,  x, -y1
    .line  x, -y1,  x, -y2
    .line -x, -y1, -x, -y2

  # Assembly
  pattern
    .layer 'topAssembly'
    .lineWidth settings.lineWidth.assembly
    .rectangle -bodyWidth/2, -bodyLength/2, bodyWidth/2, bodyLength/2
