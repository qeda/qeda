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
          x: 0.6
          y: (padParams.pitch * padParams.count/2 + 0.5) / 2
          layer: ['topCopper', 'topMask', 'intCopper', 'bottomCopper', 'bottomMask']
        pattern.addPad bossPad
        bossPad.x = -bossPad.x
        bossPad.y = -bossPad.y
        pattern.addPad bossPad

    when 'receptacle'
      padParams.pad.width = 1
      padParams.distance = 4.5
      padParams.mirror = true
      bodyWidth = 4
      bodyLength = padParams.pitch * padParams.count/2 + 2.1

      dual pattern, padParams

  pattern.setLayer 'topSilkscreen'
  lineWidth = settings.lineWidth.silkscreen
  pattern.setLineWidth lineWidth
  # Boundary
  boundWidth = 4
  boundLength = padParams.pitch * padParams.count/2 + 2.1
  padHeight = padParams.pad.height
  x = boundWidth/2
  y1 = boundLength/2
  y2 = padParams.pitch*(padParams.count/4 - 0.5) + padHeight/2 + lineWidth/2 + settings.clearance.padToSilk
  pattern.addLine { x1: -x, y1: y1, x2: x, y2: y1 }
  pattern.addLine { x1: x, y1: y1, x2: x, y2: y2 }
  pattern.addLine { x1: -x, y1: y1, x2: -x, y2: y2 }
  pattern.addLine { x1: -x, y1: -y1, x2: x, y2: -y1 }
  pattern.addLine { x1: x, y1: -y1, x2: x, y2: -y2 }
  pattern.addLine { x1: -x, y1: -y1, x2: -x, y2: -y2 }
  # RefDes
  fontSize = settings.fontSize.refDes
  pattern.addAttribute 'refDes',
    x: 0
    y: -boundLength/2 - fontSize/2 - 2*lineWidth
    halign: 'center'
    valign: 'center'

  # Assembly
  pattern.setLayer 'topAssembly'
  pattern.setLineWidth settings.lineWidth.assembly
  # Body
  pattern.addRectangle { x: -bodyWidth/2, y: -bodyLength/2, width: bodyWidth, height: bodyLength }
