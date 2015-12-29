module.exports = (symbol, element) ->
  element.refDes = 'S'
  schematic = element.schematic
  settings = symbol.settings

  pinLength = settings.pinLenght ? 4.25
  width = 10
  height = 8
  r = 1

  symbol
    .attribute 'refDes',
      x: 0
      y: -height - 1 + r
      halign: 'center'
      valign: 'bottom'
    .attribute 'name',
      x: 0
      y: r + 1
      halign: 'center'
      valign: 'top'
    .pin
      number: 1
      name: 1
      x: -width/2 - pinLength
      y: 0
      length: pinLength
      orientation: 'right'
      type: 'passive'
    .pin
      number: 2
      name: 2
      x: width/2 + pinLength
      y: 0
      length: pinLength
      orientation: 'left'
      type: 'passive'

    .lineWidth settings.lineWidth.thick
    .circle -width/2 + r, 0, r
    .circle width/2 - r, 0, r
    .line -width/2, -height/2 + r, width/2, -height/2 + r
    .line 0, -height/2 + r, 0, -height + r
