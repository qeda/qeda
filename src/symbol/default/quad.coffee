module.exports = (symbol) ->
  # Attributes
  symbol.addAttribute 'refDes',
    x: 0
    y: 0
    halign: 'center'
    valign: 'bottom'

  symbol.addAttribute 'name',
    x: 0
    y: -2
    halign: 'center'
    valign: 'top'
