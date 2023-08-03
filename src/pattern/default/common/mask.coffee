module.exports =
  dual: (pattern, housing) ->
    @rect pattern, housing

  preamble: (pattern, housing) ->
    settings = pattern.settings
    lineWidth = settings.lineWidth.courtyard
    pattern
      .layer 'topMask'
      .lineWidth lineWidth

  quad: (pattern, housing) ->
    @rect pattern, housing

  rect: (pattern, housing) ->
    if housing.maskcutout?
      [firstPad, lastPad] = pattern.extremePads()
      width = Math.max firstPad.width, lastPad.width, housing.bodyWidth.max
      height = Math.max firstPad.height, lastPad.height, housing.bodyLength.max
      width += pattern.settings.clearance.padToMask
      height += pattern.settings.clearance.padToMask

      @preamble pattern, housing
        .fill true
        .rectangle -width/2, -height/2, width/2, height/2
        .fill false

  twoPin: (pattern, housing) ->
    if housing.maskcutout?
      if housing.bodyWidth? and housing.bodyLength?
        @rect pattern, housing
      else if housing.bodyDiameter?
        @preamble pattern, housing
          .fill true
          .circle 0, 0, housing.bodyDiameter.max/2 + housing.maskCutout
          .fill false
