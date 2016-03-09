groundSymbol = (symbol, element, icon = 'signal') ->
  settings = symbol.settings
  width = 5
  height = 5

  symbol
    .attribute 'refDes',
      x: 0
      y: -settings.space.attribute
      halign: 'center'
      valign: 'bottom'
      visible: false
    .attribute 'name',
      x: 0
      y: height + settings.space.attribute
      halign: 'center'
      valign: 'top'
    .pin
      number: 1
      name: element.name
      x: 0
      y: 0
      length: 0
      orientation: 'down'
      ground: true
      invisible: true
    .line 0, 0, 0, height/2
    .lineWidth settings.lineWidth.thick
  switch icon
    when 'signal'
      symbol.polyline -width/2, height/2, width/2, height/2, 0, height, -width/2, height/2
    when 'earth'
      d = width/5
      symbol
        .line -width/2, height/2, width/2, height/2
        .line -width/2 + d, 3*height/4, width/2 - d, 3*height/4
        .line -width/2 + 2*d, height, width/2 - 2*d, height
        #.dot 0, height
    when 'chassis'
      d = width/4
      symbol
        .line -width/2, height/2, width/2, height/2
        .line -width/2, height/2, -width/2 - d, height
        .line 0, height/2, -d, height
        .line width/2, height/2, width/2 - d, height
    else
      symbol.line -width/2, height/2, width/2, height/2

module.exports = (symbol, element) ->
  element.refDes = '#PWR'
  element.power = true

  groundSymbol symbol, element
  earth = element.cloneSymbol symbol
  groundSymbol earth, element, 'earth'
  chassis = element.cloneSymbol symbol
  groundSymbol chassis, element, 'chassis'
