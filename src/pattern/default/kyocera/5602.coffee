dual = require '../common/dual'

module.exports = (pattern, element) ->
  housing = element.housing
  settings = pattern.settings
  pattern.name ?= 'KYOCERA_' + element.name


  padParams =
    pitch: 0.4
    count: Object.keys(element.pins).length

  switch housing.type

    when 'plug'
      padParams.pad =
        type: 'smd'
        shape: 'rectangle'
        width: 0.7
        height: 0.23
      padParams.distance = 3.31

      pattern.setLayer 'top'
      dual pattern, padParams

    when 'receptacle'
      padParams.pad =
        type: 'smd'
        shape: 'rectangle'
        width: 1
        height: 0.23
      padParams.distance = 4

      pattern.setLayer 'top'
      dual pattern, padParams
